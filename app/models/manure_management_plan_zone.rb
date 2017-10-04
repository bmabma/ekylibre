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
# == Table: manure_management_plan_zones
#
#  activity_production_id :integer          not null
#  administrative_area    :string
#  created_at             :datetime         not null
#  creator_id             :integer
#  cultivation_variety    :string
#  expected_yield         :decimal(19, 4)
#  id                     :integer          not null, primary key
#  lock_version           :integer          default(0), not null
#  plan_id                :integer          not null
#  soil_nature            :string
#  updated_at             :datetime         not null
#  updater_id             :integer
#
class ManureManagementPlanZone < Ekylibre::Record::Base
  belongs_to :plan, class_name: 'ManureManagementPlan', inverse_of: :zones
  belongs_to :activity_production
  has_one :activity, through: :activity_production
  has_one :campaign, through: :plan
  has_one :support, through: :activity_production
  has_one :cultivable_zone, through: :activity_production, source: :support
  has_many :manure_approach_applications
  has_many :targets, foreign_key: :manuring_zone_id, class_name: "ManureManagementPlanInterventionTarget"
  has_many :manuring_interventions, through: :targets, class_name: "ManureManagementPlanIntervention"
  refers_to :soil_nature
  refers_to :cultivation_variety, class_name: 'Variety'
  refers_to :administrative_area
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :expected_yield, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :activity_production, :plan, presence: true
  # ]VALIDATORS]
  validates :soil_nature, presence: true

  delegate :locked?, :opened_at, to: :plan
  delegate :name, to: :cultivable_zone
  delegate :support_shape, :irrigated, :usage, to: :activity_production

  alias_attribute :approach_applications, :manure_approach_applications

  accepts_nested_attributes_for :manure_approach_applications

  protect do
    locked?
  end

  scope :of_campaign, lambda{ |campaign|
    if campaign.is_a?(Fixnum)
      where(campaign_id: campaign)
    else
      where(campaign_id: campaign.id)
    end
  }

  # def estimate_expected_yield
  #   if computation_method
  #     self.expected_yield = Calculus::ManureManagementPlan.estimate_expected_yield(parameters).to_f(plan.mass_density_unit)
  #   end
  # end

  # def compute
  #   for name, value in Calculus::ManureManagementPlan.compute(parameters)
  #     if %w[absorbed_nitrogen_at_opening expected_yield humus_mineralization intermediate_cultivation_residue_mineralization irrigation_water_nitrogen maximum_nitrogen_input meadow_humus_mineralization mineral_nitrogen_at_opening nitrogen_at_closing nitrogen_input nitrogen_need organic_fertilizer_mineral_fraction previous_cultivation_residue_mineralization soil_production].include?(name.to_s)
  #       send("#{name}=", value.to_f(:kilogram_per_hectare))
  #     end
  #   end
  #   save!
  # end

  # def parameters
  #   hash = {
  #     available_water_capacity: available_water_capacity,
  #     opened_at: opened_at,
  #     support: activity_production
  #   }
  #   if activity_production.usage
  #     hash[:production_usage] = Nomen::ProductionUsage[activity_production.usage]
  #   end
  #   if computation_method && Calculus::ManureManagementPlan.method_exist?(computation_method.to_sym)
  #     hash[:method] = computation_method.to_sym
  #   else
  #     Rails.logger.warn "Method #{computation_method} doesn't exist. Use default method instead."
  #     hash[:method] = :external
  #   end
  #   if administrative_area
  #     hash[:administrative_area] = Nomen::AdministrativeArea[administrative_area]
  #   end
  #   hash[:variety] = Nomen::Variety[cultivation_variety] if cultivation_variety
  #   hash[:soil_nature] = Nomen::SoilNature[soil_nature] if soil_nature
  #   if expected_yield
  #     hash[:expected_yield] = expected_yield.in(plan.mass_density_unit)
  #   end
  #   hash
  # end

  def shape
    support_shape
  end

  # TODO: Compute available from parcels or CZ ?
  def available_water_capacity
    0.0.in_liter_per_hectare
  end

  # To have human_name in report
  def soil_nature_name
    unless soil_nature && item = Nomen::SoilNature[soil_nature].human_name
      return nil
    end
    item
  end

  def cultivation_variety_name
    unless cultivation_variety && item = Nomen::Variety[cultivation_variety].human_name
      return nil
    end
    item
  end

  def compute
    results = {}
    approach_applications.map { |approach| results[approach.supply_nature] = approach.compute}
    return results
  end

end
