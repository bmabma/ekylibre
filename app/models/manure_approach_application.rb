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
# == Table: manure_approach_applications
#
#  approach_id                      :integer
#  id                               :integer          not null, primary key
#  manure_management_plan_nature_id :integer
#  manure_management_plan_zone_id   :integer
#  parameters                       :jsonb
#  results                          :jsonb
#  supply_nature                    :string
#

class ManureApproachApplication < Ekylibre::Record::Base
  belongs_to :manure_management_plan_zone
  belongs_to :approach
  belongs_to :manure_management_plan_nature
  has_one :manure_management_plan, through: :manure_management_plan_nature

  delegate :questions, to: :approach
  delegate :name, to: :approach
  delegate :supply_nature, to: :manure_management_plan_nature

  alias_attribute :plan, :manure_management_plan
  alias_attribute :nature, :manure_management_plan_nature
  alias_attribute :zone, :manure_management_plan_zone

  validates :approach_id, presence: true

  def self.most_relevant_approach(shape, supply_nature)
    # Return the most relevant model for a given location

    # Here we use multiple queries because we can't use comparison on aggregations efficiently.
    # We extract some results because otherwise we would have to compute it multiple times.
    # For exemple by finding the approach id associated with the largest intersection between an approach shape and the shape(param)

    # Return the area (numeric value) for the largest intersection of an approach and the shape
    #     shape = manure_management_plan_zone.shape
    #     supply_nature = manure_management_plan_nature.supply_nature
    max = ActiveRecord::Base.connection.execute("(SELECT MAX(ST_AREA(ST_Intersection(Ap.shape,#{Charta.new_geometry(shape).geom}))) FROM Approaches Ap)").values.first.first

    # Returns the approaches that intersect the most (with larger area) with the shape
    intersecting_with_largest_area = ActiveRecord::Base.connection.execute("
                                          SELECT approach.id, ST_area(approach.shape)
                                          FROM Approaches approach
                                          where approach.id in (SELECT area_tab.id
                                                                FROM (SELECT App.id, ST_AREA(ST_Intersection(App.shape,#{Charta.new_geometry(shape).geom})) AS int_area
                                                                      FROM approaches App
                                                                      WHERE supply_nature = '#{supply_nature}') area_tab
                                                                WHERE #{max} = cast(int_area AS numeric))").values

    # Find the smallest intersecting area
    # because we would have to compute all area multiple time if using aggregation to find the smallest area, and then the corresponding id,
    # I choosed to use ruby

    min_couple = intersecting_with_largest_area.first
    intersecting_with_largest_area.each do |couple|
      min_couple = couple if couple[1] < min_couple[1]
    end
    return nil if min_couple.nil?
    min_couple[0]
  end

  def compute
    approach = Calculus::ManureManagementPlan::Approach.build_approach(self)
    self.results = {
      yields: approach.estimate_expected_yield,
      needs: approach.estimated_needs,
      soil_supplies: approach.soil_supplies,
      irrigation: approach.estimate_irrigation_water_nitrogen ,
      organic_input: approach.estimate_organic_fertilizer_mineral_fraction ,
      input: approach.estimated_input,
      annual_nitrogen_animal_output: approach.annual_nitrogen_animal_output,
      supply: approach.estimated_supply }
    self.save
    return self.results
  end


end
