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
    case params[:controller]
    when "backend/events"
      link_to content_tag(:i)+" Relationship", relationship_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/entities"
      link_to content_tag(:i)+" Relationship", relationship_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/journals"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/draft_journals"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/accounts"
      if params[:action] == "reconciliation"
        link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
      else
        link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
      end
    when "backend/trial_balances"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/general_ledgers"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/fixed_assets"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/tax_declarations"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/cashes"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/loans"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/cash_transfers"
      link_to content_tag(:i)+" Accountancy", accountancy_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/sales"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/sale_opportunities"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/subscriptions"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/purchases"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/contracts"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/incoming_payments"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/purchase_payments"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/deposits"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/outgoing_payment_lists"
      link_to content_tag(:i)+" Trade", trade_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/matters"
      link_to content_tag(:i)+" Stocks", stocks_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/trackings"
      link_to content_tag(:i)+" Stocks", stocks_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/inventories"
      link_to content_tag(:i)+" Stocks", stocks_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/parcels"
      link_to content_tag(:i)+" Stocks", stocks_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/deliveries"
      link_to content_tag(:i)+" Stocks", stocks_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/activities"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/interventions"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/analyses"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/issues"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/inspections"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/plant_countings"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/cultivable_zones"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/land_parcels"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/plants"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/animals"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/animal_groups"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/sensors"
      link_to content_tag(:i)+" Production", production_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/payslips"
      link_to content_tag(:i)+" HR", humans_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/payslip_payments"
      link_to content_tag(:i)+" HR", humans_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/documents"
      link_to content_tag(:i)+" Tools", tools_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/cap_statements"
      link_to content_tag(:i)+" Tools", tools_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/listings"
      link_to content_tag(:i)+" Tools", tools_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/exports"
      link_to content_tag(:i)+" Tools", tools_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/imports"
      link_to content_tag(:i)+" Tools", tools_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/myselves"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/dashboards"
      if params[:action] == "index"
        link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
      end
    when "backend/companies"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/integrations"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/map_layers"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/labels"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/custom_fields"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/document_templates"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/sequences"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/teams"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/settings"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/roles"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/users"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/invitations"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/registrations"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/postal_zones"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/districts"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/financial_years"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/taxes"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/sale_natures"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/purchase_natures"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/subscription_natures"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/incoming_payment_modes"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/outgoing_payment_modes"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/product_nature_categories"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/product_natures"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/product_nature_variants"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/catalogs"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/workers"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/equipments"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/buildings"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/building_divisions"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/settlements"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
    when "backend/payslip_natures"
      link_to content_tag(:i)+" Settings", settings_backend_dashboards_path, class: "dashboard-item snippet-title"
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
