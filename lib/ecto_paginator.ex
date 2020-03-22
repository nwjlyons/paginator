defmodule EctoPaginator do
  @moduledoc """
  Pagination library for Ecto

  # Usage

  ## Context

    defmodule Foo.Accounts do
      import Ecto.Query, warn: false
      alias Foo.Repo

      alias Foo.Accounts.User

      def list_users_with_pagination(page_number, paginate_by) do
        list_users_query()
        |> EctoPaginator.paginate(page_number, paginate_by)
        |> Repo.all()
      end

      def count_users() do
        Repo.aggregate(list_users_query(), :count)
      end

      defp list_users_query() do
        from(User)
        |> order_by(asc: :inserted_at)
      end
    end

  ## Controller

    defmodule FooWeb.UserController do
      use FooWeb, :controller

      alias Foo.Accounts
      alias Foo.Repo

      @paginate_by 20

      def index(conn, %{"page" => current_page}) do
        {current_page, _} = Integer.parse(current_page)

        users = Accounts.list_users_with_pagination(current_page, @paginate_by)
        paginator = EctoPaginator.paginate_helper(current_page, @paginate_by, Accounts.count_users())

        render(conn, "index.html", users: users, paginator: paginator)
      end

      def index(conn, _params), do: index(conn, %{"page" => "1"})
    end

  ## Template

    <%= if @paginator.previous_page_number do %>
      <a href="?page=1">First</a>
      <a href="?page=<%= @paginator.previous_page_number %>">Previous</a>
    <% end %>

    Page <%= @paginator.current_page_number %> of <%= @paginator.num_pages %>.

    <%= if @paginator.next_page_number do %>
      <a href="?page=<%= @paginator.next_page_number %>">Next</a>
      <a href="?page=<%= @paginator.num_pages %>">Last</a>
    <% end %>
  """
  import Ecto.Query, warn: false

  @enforce_keys [:current_page_number, :next_page_number, :previous_page_number, :num_pages]
  defstruct [:current_page_number, :next_page_number, :previous_page_number, :num_pages]

  defguardp is_positive_integer(number) when is_integer(number) and number >= 1

  @doc """
  Paginate an Ecto.Query by adding offset and limit expressions

  Example:

      def list_users_with_pagination(page_number, paginate_by) do
        list_users_query()
        |> EctoPaginator.paginate(page_number, paginate_by)
        |> Repo.all()
      end
  """
  def paginate(%Ecto.Query{} = query, page_number, paginate_by)
      when is_positive_integer(page_number) and is_positive_integer(paginate_by) do
    offset_value = (page_number - 1) * paginate_by

    query
    |> offset(^offset_value)
    |> limit(^paginate_by)
  end

  @doc """
  Helper function that makes a struct that can be used for building "next" and "previous" links in templates

  Example:

      <%= if @paginator.previous_page_number do %>
          <a href="?page=1">First</a>
          <a href="?page=<%= @paginator.previous_page_number %>">Previous</a>
      <% end %>

      Page <%= @paginator.current_page_number %> of <%= @paginator.num_pages %>.

      <%= if @paginator.next_page_number do %>
          <a href="?page=<%= @paginator.next_page_number %>">Next</a>
          <a href="?page=<%= @paginator.num_pages %>">Last</a>
      <% end %>
  """
  def paginate_helper(page_number, paginate_by, total)
      when is_positive_integer(page_number) and is_positive_integer(paginate_by) and
             is_positive_integer(total) do
    next_page_number = page_number + 1
    previous_page_number = page_number - 1
    num_pages = div(total, paginate_by)

    %EctoPaginator{
      current_page_number: page_number,
      next_page_number: next_page_number(next_page_number, num_pages),
      previous_page_number: previous_page_number(previous_page_number),
      num_pages: div(total, paginate_by)
    }
  end

  defp next_page_number(next_page_number, num_pages) do
    if next_page_number <= num_pages do
      next_page_number
    else
      nil
    end
  end

  defp previous_page_number(previous_page_number) do
    if previous_page_number <= 0 do
      nil
    else
      previous_page_number
    end
  end
end
