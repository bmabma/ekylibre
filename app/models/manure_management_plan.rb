# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: manure_management_plans
#
#  annotation                            :text
#  campaign_id                           :integer          not null
#  created_at                            :datetime         not null
#  creator_id                            :integer
#  data_unit                             :string
#  external_building_attendance_in_month :decimal(19, 4)
#  id                                    :integer          not null, primary key
#  lock_version                          :integer          default(0), not null
#  locked                                :boolean          default(FALSE), not null
#  milk_annual_production_in_liter       :integer
#  name                                  :string           not null
#  opened_at                             :datetime         not null
#  recommender_id                        :integer          not null
#  updated_at                            :datetime         not null
#  updater_id                            :integer
#
class ManureManagementPlan < Ekylibre::Record::Base
  include Attachable
  belongs_to :campaign
  belongs_to :recommender, class_name: 'Entity'
  has_many :manure_management_plan_natures
  has_many :zones, class_name: 'ManureManagementPlanZone', dependent: :destroy, inverse_of: :plan, foreign_key: :plan_id
  has_many :manuring_interventions, class_name: 'ManureManagementPlanIntervention', dependent: :destroy, inverse_of: :plan, foreign_key: :plan_id
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :annotation, length: { maximum: 500_000 }, allow_blank: true
  validates :data_unit, length: { maximum: 500 }, allow_blank: true
  validates :external_building_attendance_in_month, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :locked, inclusion: { in: [true, false] }
  validates :milk_annual_production_in_liter, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :opened_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :campaign, :recommender, presence: true
  # ]VALIDATORS]

  accepts_nested_attributes_for :zones, :manure_management_plan_natures, :manuring_interventions
  alias_attribute :natures, :manure_management_plan_natures

  protect do
    locked?
  end

  # after_save :compute
  scope :of_campaign, lambda{ |campaign|
    if campaign.is_a?(Fixnum)
      where(campaign_id: campaign)
    else
      where(campaign_id: campaign.id)
    end
  }

  def self.manure_georeadings
    natures = ManureManagementPlan.manure_georeading_types
    Georeading.where(kind: natures)
  end

  def compute
    results = []
    zones.map { |zone| results << {zone.id => zone.compute}}
    return results
  end

  def self.create_for_campaign(campaign: nil, user: nil, soil_natures: {}, manure_natures: [], approach_name: nil,params: {})
    # soil_natures is a hash like { <(string)activity_production_id> => <(string)soil_nature>}
    if campaign.nil?
      campaign = Campaign.last
      raise 'no Campaign found' if campaign.nil?
    end
    if user.nil?
      user = User.first
      raise 'no User found' if user.nil?
    end

    manure_natures = ['N'] if manure_natures.empty?
    manure_management_plan = ManureManagementPlan.new(campaign: campaign,
                                                      data_unit: :kilogram_per_hectare,
                                                      opened_at: Time.new(campaign.harvest_year, 2, 1).to_datetime,
                                                      recommender_id: user.person_id,
                                                      name: 'Fumure ' + campaign['harvest_year'].to_s,
                                                      milk_annual_production_in_liter: params[:milk_annual_production_in_liter] || 0,
                                                      external_building_attendance_in_month: params[:external_building_attendance_in_month])


    ActivityProduction.of_campaign(campaign).of_activity_families('plant_farming').each do |activity_production|
      admin_area = Nomen::AdministrativeArea.find_by(code: activity_production.support.administrative_area)
      admin_area_name = admin_area.name unless admin_area.nil?
      manure_management_plan.zones.new(
        activity_production: activity_production,
        soil_nature: soil_natures[activity_production.id.to_s] || 'champagne_soil',
        cultivation_variety: activity_production.cultivation_variety,
        administrative_area: admin_area_name
      )
    end
    manure_natures.each do |manure_nature|
      mmp_nature = manure_management_plan.natures.new(supply_nature: manure_nature)
      manure_management_plan.zones.each do |zone|
        if approach_name.nil?
          approach = Approach.find(ManureApproachApplication.most_relevant_approach(zone.support_shape, mmp_nature.supply_nature))
        else
          approach = Approach.find_by_name(approach_name)
        end
        zone.manure_approach_applications.new(manure_management_plan_nature: mmp_nature,
                                              parameters: {},
                                              results: {},
                                              approach_id: approach.id)
      end
    end
    manure_management_plan
  end

  def zones_in_vulnerable_area
    res = []
    ActiveRecord::Base.connection.execute("SELECT distinct MMPZ.id
                                                  FROM MANURE_MANAGEMENT_PLANS as MMP
                                                  JOIN MANURE_MANAGEMENT_PLAN_ZONES as MMPZ ON MMPZ.plan_id = MMP.id
                                                  JOIN ACTIVITY_PRODUCTIONS as AP on MMPZ.activity_production_id = AP.id
                                                  LEFT JOIN REGULATORY_ZONES as RZ on ST_Intersects(RZ.shape,AP.support_shape)
                                                  WHERE RZ.type = 'VulnerableZone'
                                                  ;").values.map(&:first)
  end

  def questions
    question_hash = {}
    zones.each do |zone|
      question_hash[zone_id] = zone.questions
    end
    question_hash
  end

  def build_missing_zones
    active = false
    active = true if zones.empty?
    return false unless campaign
    campaign.activity_productions.includes(:support).order(:activity_id, 'products.name').each do |activity_production|
      # activity_production.active? return all activies except fallow_land
      next unless activity_production.support.is_a?(LandParcel) && activity_production.active?
      next if zones.find_by(activity_production: activity_production)
      zone = zones.build(
        activity_production: activity_production,
        administrative_area: activity_production.support.administrative_area,
        cultivation_variety: activity_production.cultivation_variety,
        soil_nature: activity_production.support.soil_nature || activity_production.support.estimated_soil_nature
      )
      zone.estimate_expected_yield
    end
  end

  def self.can_be_created(campaign)
    budgets_done(campaign)['valid'] && !ManureManagementPlanNature.available_natures.nil?
  end

  def self.budgets_done(campaign)
    activities_prod = ActivityProduction.of_campaign(campaign).of_activity_families('plant_farming')

    missing_budgets = []
    activities_prod.each do |activity_production|
      missing_budgets << activity_production.budgets.of_campaign(campaign).select { |budget| budget.revenues.empty? }
    end
    missing_info = { budget: missing_budgets.reject(&:empty?),
                     cultivation_variety: activities_prod.select { |act| act.cultivation_variety.nil? } }
    activities_prod.select { |act| act.cultivation_variety.nil? }

    missing_info['valid'] = missing_info[:budget].empty? && missing_info[:cultivation_variety].empty?
    # check soil nature

    missing_info
  end

  def mass_density_unit
    :quintal_per_hectare
  end

  def self.manure_georeading_types
    [:well, :water, :drinkingwater, :bathing_place, :shellfish_waters, :steep_slopes]
  end
end
