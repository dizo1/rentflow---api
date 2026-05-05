module Paginatable
  extend ActiveSupport::Concern

  def paginate(collection)
    page = params[:page].to_i
    page = 1 if page < 1
    per_page = params[:per_page].to_i
    per_page = 20 if per_page < 1 || per_page > 100

    paginated = collection.page(page).per(per_page)

    {
      data: paginated,
      meta: {
        current_page: paginated.current_page,
        total_pages: paginated.total_pages,
        total_count: paginated.total_count,
        per_page: per_page
      }
    }
  end
end