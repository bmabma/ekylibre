# Helper to add record-to-record navigation.
module NavigationHelper
  # Used when missing a scope.
  class MissingScopeError < NoMethodError
    def initialize(scope, resource, backtrace, *args)
      error_message = "Scope `#{scope}` unknown in resource #{resource}."
      super(error_message, backtrace, *args)
    end
  end

  # Used when trying to order with non-existent table columns.
  class OrderingCriterionNotFound < ActiveRecord::StatementInvalid
    def initialize(pg_error, *args)
      column = pg_error.message.split('"').second
      error_message = "Column #{column} is specified in order but isn't present in table columns."
      super(error_message, pg_error.backtrace, *args)
    end
  end

  def navigation(resource, order: { id: :asc }, naming_method: :name, scope: nil)
    order = { order.to_sym => :asc } unless order.respond_to?(:keys)
    nexts = next_records(resource, order, scope)

    content_for :heading_toolbar do
      render 'backend/shared/record_navigation',
             previous: named(nexts[:down], naming_method),
             following: named(nexts[:up], naming_method)
    end
  end
  
  def tours(page)
    Tour.where(page: page, language: current_user.language)
  end
  
  def sidebar_dashboard_item
    puts "____________________#{params[:controller]}"
    case params[:controller]
    when "backend/events"
      link_to content_tag(:i)+" Relationship", "#", class: "dashboard-item snippet-title"
    when "backend/entities"
      link_to content_tag(:i)+" Relationship", "#", class: "dashboard-item snippet-title"
    when "backend/journals"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/draft_journals"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/accounts"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/trial_balances"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/general_ledgers"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/fixed_assets"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/tax_declarations"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/cashes"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/loans"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/cash_transfers"
      link_to content_tag(:i)+" Accountancy", "#", class: "dashboard-item snippet-title"
    when "backend/sales"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/sale_opportunities"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/subscriptions"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/purchases"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/contracts"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/incoming_payments"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/purchase_payments"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/deposits"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/outgoing_payment_lists"
      link_to content_tag(:i)+" Trade", "#", class: "dashboard-item snippet-title"
    when "backend/matters"
      link_to content_tag(:i)+" Stocks", "#", class: "dashboard-item snippet-title"
    when "backend/trackings"
      link_to content_tag(:i)+" Stocks", "#", class: "dashboard-item snippet-title"
    when "backend/inventories"
      link_to content_tag(:i)+" Stocks", "#", class: "dashboard-item snippet-title"
    when "backend/parcels"
      link_to content_tag(:i)+" Stocks", "#", class: "dashboard-item snippet-title"
    when "backend/deliveries"
      link_to content_tag(:i)+" Stocks", "#", class: "dashboard-item snippet-title"
    when "backend/activities"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/interventions"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/analyses"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/issues"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/inspections"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/plant_countings"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/cultivable_zones"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/land_parcels"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/plants"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/animals"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/animal_groups"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/sensors"
      link_to content_tag(:i)+" Production", "#", class: "dashboard-item snippet-title"
    when "backend/payslips"
      link_to content_tag(:i)+" HR", "#", class: "dashboard-item snippet-title"
    when "backend/payslip_payments"
      link_to content_tag(:i)+" HR", "#", class: "dashboard-item snippet-title"
    when "backend/documents"
      link_to content_tag(:i)+" Tools", "#", class: "dashboard-item snippet-title"
    when "backend/cap_statements"
      link_to content_tag(:i)+" Tools", "#", class: "dashboard-item snippet-title"
    when "backend/listings"
      link_to content_tag(:i)+" Tools", "#", class: "dashboard-item snippet-title"
    when "backend/exports"
      link_to content_tag(:i)+" Tools", "#", class: "dashboard-item snippet-title"
    when "backend/imports"
      link_to content_tag(:i)+" Tools", "#", class: "dashboard-item snippet-title"
    when "backend/myselves"
      link_to content_tag(:i)+" Settings", "#", class: "dashboard-item snippet-title"
    when "backend/dashboards"
    when "backend/companies"
    when "backend/integrations"
    when "backend/map_layers"
    when "backend/labels"
    when "backend/custom_fields"
    when "backend/document_templates"
    when "backend/sequences"
    when "backend/teams"
    when "backend/settings"
    when "backend/roles"
    when "backend/users"
    when "backend/invitations"
    when "backend/registrations"
    when "backend/postal_zones"
    when "backend/districts"
    when "backend/accounts"
    when "backend/financial_years"
    when "backend/taxes"
    when "backend/sale_natures"
    when "backend/purchase_natures"
    when "backend/subscription_natures"
    when "backend/incoming_payment_modes"
    when "backend/outgoing_payment_modes"
    when "backend/product_nature_categories"
    when "backend/product_natures"
    when "backend/product_nature_variants"
    when "backend/catalogs"
    when "backend/workers"
    when "backend/equipments"
    when "backend/buildings"
    when "backend/building_divisions"
    when "backend/settlements"
    when "backend/payslip_natures"
    end
  end

  private

  def named(collection, naming_method)
    {
      record: collection.first,
      name:   name_for(collection.first, naming_method)
    }
  rescue ActiveRecord::StatementInvalid => e
    raise e unless (pg_error = e.original_exception).is_a?(PG::UndefinedColumn)
    raise OrderingCriterionNotFound, pg_error
  end

  def next_records(resource, order, scope)
    matching_attrs = resource.attributes.slice(*order.keys.map(&:to_s))
    other_records  = navigable(resource.class, order, scope, resource.id).order(**order)
    reversed = (order.first.last =~ /desc/)

    lists = %i[down up].map do |dir|
      [dir, matching_attrs.reduce(other_records, &get_next_record_method(going: dir, reverse: reversed))]
    end.to_h
    lists[:down] = lists[:down].reverse_order
    lists
  end

  def name_for(record, method)
    return nil if method.blank?
    Maybe(record).send(method.to_sym).or_nil
  end

  def navigable(items, order, scope, excluded)
    scoped   = scope
    scoped &&= items.send(scope)
    scoped ||= items
    scoped.where.not(id: excluded).order(**order)
  rescue NoMethodError => e
    raise MissingScopeError.new(e.name, e.missing_name, e.backtrace, *e.args)
  end

  def get_next_record_method(going: :up, reverse: false)
    operator = case going
               when /up/   then reverse ? '<=' : '>='
               when /down/ then reverse ? '>=' : '<='
               end
    lambda do |resources, condition|
      key, value = *condition
      resources.where("#{key} #{operator} ?", value)
    end
  end
end
