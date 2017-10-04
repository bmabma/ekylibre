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
# == Table: manure_management_plan_interventions
#
#  actions        :string
#  created_at     :datetime         not null
#  creator_id     :integer
#  description    :text
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  name           :string           not null
#  plan_id        :integer          not null
#  procedure_name :string           not null
#  quantity       :decimal(19, 4)
#  started_at     :datetime         not null
#  stopped_at     :datetime         not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#  variant_id     :integer          not null
#
class ManureManagementPlanIntervention < Ekylibre::Record::Base
  belongs_to :plan, class_name: 'ManureManagementPlan', inverse_of: :manuring_interventions
  belongs_to :variant, class_name: 'ProductNatureVariant'
  has_many :targets, class_name: 'ManureManagementPlanInterventionTarget', inverse_of: :manuring_intervention, foreign_key: :manuring_intervention_id
  has_one :campaign, through: :plan
  enumerize :procedure_name, in: Procedo.procedure_names, i18n_scope: ['procedures']
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :actions, length: { maximum: 500 }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :plan, :procedure_name, :variant, presence: true
  validates :quantity, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :stopped_at, presence: true, timeliness: { on_or_after: ->(manure_management_plan_intervention) { manure_management_plan_intervention.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  serialize :actions, SymbolArray

  delegate :locked?, :opened_at, to: :plan

  def self.create_for_plan(params)
    manure_management_plan = ManureManagementPlan.find(params["id"])
    intervention = ManureManagementPlanIntervention.new(params["manure_management_plan_intervention"])

    intervention.plan = manure_management_plan
    params["manure_zones_ids"].split(',').each do |mmpz_id|
      intervention.targets.new({manuring_intervention: intervention,manuring_zone: ManureManagementPlanZone.find(mmpz_id)})
    end

    intervention.save
    return intervention
  end

end
