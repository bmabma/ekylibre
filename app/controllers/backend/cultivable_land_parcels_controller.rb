# coding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::CultivableLandParcelsController < BackendController
  manage_restfully

  unroll

  # INDEX

  list do |t|
    t.column :name, url: true
    t.column :work_number
    #t.column :identification_number
    t.column :area
    # t.column :unit
  end

  # SHOW

  # content plant on current cultivable land parcel
  list(:contained_products, :model => :product_localizations, :conditions => {container_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :product, url: true
    t.column :nature
    t.column :started_at
    t.column :stopped_at
  end

  # content production on current cultivable land parcel
  list(:productions, :model => :production_supports, :conditions => {storage_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :production, url: true
    t.column :exclusive
    t.column :started_at
    t.column :stopped_at
  end

  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :intervention, url: true
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
  end

end
