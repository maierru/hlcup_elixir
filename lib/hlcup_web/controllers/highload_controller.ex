defmodule HlcupWeb.HighloadController do
  use HlcupWeb, :controller

  alias Hlcup.Storage
  require Logger
  def item(conn, %{"type" => type, "id" => id_str}) do

    # render conn, "index.html"
    case Integer.parse(id_str) do
      :error ->
          Logger.debug "Не удалось распарсить строку в число для запроса /#{type}/#{id_str}"
          result_404(conn,%{})
      {id,_} ->
        result = case type do
          "users" ->
            case Storage.find(:users,id) do
              [] ->
                Logger.warn "Не удалось найти запись /#{type}/#{id}"
                {:not_found, %{}}
              [{id,birth_date,email,gender,first_name,last_name}] ->
                {:ok, %{
                  id: id,
                  birth_date: birth_date,
                  email: email,
                  gender: gender,
                  first_name: first_name,
                  last_name: last_name
                }}
            end
          "locations" ->
            case Storage.find(:locations,id) do
              [] ->
                Logger.warn "Не удалось найти запись /#{type}/#{id}"
                {:not_found, %{}}
              [{id,distance,country,city,place}] ->
                {:ok, %{
                  id: id,
                  distance: distance,
                  country: country,
                  city: city,
                  place: place
                }}
            end
          "visits" ->
            case Storage.find(:visits,id) do
              [] ->
                Logger.warn "Не удалось найти запись /#{type}/#{id}"
                {:not_found, %{}}
              [{id,user,location,visited_at,mark}] ->
                {:ok, %{
                  id: id,
                  user: user,
                  location: location,
                  visited_at: visited_at,
                  mark: mark
                }}
            end
          _ ->
            Logger.error "Не известный тип запроса /#{type}/#{id_str}"
            {:error, %{}}
        end

        case result do
          {:ok, object} ->
            result_200(conn,object)
          {:not_found, object} ->
            result_404(conn,object)
          {:error, object} ->
            result_400(conn, object)
          _ ->
            result_500(conn)
        end

    end


  end



  def user_visits(conn, params) do
    # p = %{id: nil, fromDate: nil, toDate: nil, country: nil, toDistance: nil}

    #
    if int_or_nil?(params, "fromDate") && int_or_nil?(params, "toDate") && int_or_nil?(params, "toDistance") do

      p = Map.put(%{}, :id, Map.get(params, "id"))
      p = Map.put(p, :fromDate, get_int_or_nil_from(params, "fromDate"))
      p = Map.put(p, :toDate, get_int_or_nil_from(params, "toDate") )
      # TODO: lowercased?
      p = Map.put(p, :country, Map.get(params, "country"))
      p = Map.put(p, :toDistance, get_int_or_nil_from(params, "toDistance") )

      case p do
        %{id: id, fromDate: fromDate, toDate: toDate, country: country, toDistance: toDistance} ->
          case Integer.parse(id) do
            {user_id, _} ->
              case Storage.find_users_visits_with_locations(user_id, [fromDate,toDate], [country, toDistance]) do
                {:user_not_found, _} ->
                  result_404(conn, %{})
                {:error, _} ->
                  result_500(conn)
                [] ->
                  result_200(conn,%{visits: [] })
                visits ->
                  v = Enum.map(visits, fn visit -> format_visit(visit) end)
                  result_200(conn,%{visits: v })
              end
            :error ->
              # GET: /users/somethingstringhere/visits?fromDate=1
              result_404(conn, %{})
          end
        _ ->
          result_500(conn)
      end


    else

      # GET: /users/1/visits?fromDate=abracadbra
      result_400(conn, %{})

    end

  end

  def int_or_nil?(map, key) do
    case Map.get(map, key) do
      nil ->
        true
      val ->
        case Integer.parse(val) do
          {_int, ""} ->
            true
          # 4Rp9hAfNGhIswrBWkzt2Kus5ImLe7NIW
          {_,_} ->
            false
          :error ->
            false
        end
    end

  end

  def format_visit({_id,_user,location,visited_at,mark}) do
    place = case Storage.find(:locations,location) do
        [{_id,_distance,_country,_city,thisplace}] -> thisplace
        [] -> ""
      end
    %{
      mark: mark,
      visited_at: visited_at,
      place: place
    }
  end

  def valid_gender?(params) do
    case Map.fetch(params, "gender") do
      :error ->
        true
      {:ok, "f"} ->
        true
      {:ok, "m"} ->
        true
      _ ->
        false
    end
  end

  def loc_avg(conn, params) do

    if int_if_exist?(params, "fromDate") && int_if_exist?(params, "toDate") && int_if_exist?(params, "fromAge") && int_if_exist?(params, "toAge") && valid_gender?(params) do

      p = Map.put(%{}, :id, get_int_or_nil_from(params, "id"))
      p = Map.put(p, :fromDate, get_int_or_nil_from(params, "fromDate"))
      p = Map.put(p, :toDate, get_int_or_nil_from(params, "toDate") )
      p = Map.put(p, :fromAge, get_int_or_nil_from(params, "fromAge"))
      p = Map.put(p, :toAge, get_int_or_nil_from(params, "toAge") )
      # TODO: lowercased?
      p = Map.put(p, :gender, Map.get(params, "gender"))

      case p do
        %{"id" => nil} ->
          result_404(conn, %{})
        %{id: locationid, fromDate: fromDate, toDate: toDate, fromAge: fromAge, toAge: toAge, gender: gender}  ->
          avg = Storage.location_average_point(locationid, [from_date: fromDate, to_date: toDate, fromAge: fromAge, toAge: toAge, gender: gender])
          case avg do
            {:not_found, "Место не найдено"} ->
              result_404(conn, %{})
            _ ->
              result_200(conn,%{"avg": avg})
          end

        _ ->
           result_404(conn, %{})
      end

    else
      result_400(conn, %{})
    end

  end

  def exist_params?(map, type) do
    case type do
      "users" ->
        Map.has_key?(map, "birth_date") || Map.has_key?(map, "email") || Map.has_key?(map, "gender") || Map.has_key?(map, "first_name") || Map.has_key?(map, "last_name")
      "locations" ->
        # Logger.debug map
        Map.has_key?(map, "distance") || Map.has_key?(map, "country") || Map.has_key?(map, "city") || Map.has_key?(map, "place")
      "visits" ->
        Map.has_key?(map, "user") || Map.has_key?(map, "location") || Map.has_key?(map, "visited_at") || Map.has_key?(map, "mark")
      _ ->
        true
    end
  end

  def update_record(conn, params) do

    if int_or_nil?(params, "item_id") do

      id = get_int_or_nil_from(params, "item_id")
      type = Map.get(params, "type")

      if !exist_params?(params, type) do
        Logger.debug "Не переданы параметры для обновления"
        result_400(conn, %{})
      else
        case id do
          nil ->
            result_404(conn, %{})
          _ ->
            case type do
              "users" ->
                # когда в теле запроса приходит нил в одном из параметров или в нескольких
                case Storage.find(:users,id) do
                  [] ->
                    result_404(conn, %{})
                  _ ->
                    if not_nil?(params, "birth_date") && not_nil?(params,  "email") && not_nil?(params,  "gender") && not_nil?(params, "first_name") && not_nil?(params, "last_name") do
                      p = %{}
                      case Map.fetch(params, "birth_date") do
                        :error ->
                          ""
                        {:ok, birth_date} ->
                            p = Map.put(p, :birth_date, birth_date)
                      end
                      case Map.fetch(params, "email") do
                        :error ->
                          ""
                        {:ok, email} ->
                            p = Map.put(p, :email, email)
                      end
                      case Map.fetch(params, "gender") do
                        :error ->
                          ""
                        {:ok, gender} ->
                            p = Map.put(p, :gender, gender)
                      end
                      case Map.fetch(params, "first_name") do
                        :error ->
                          ""
                        {:ok, first_name} ->
                            p = Map.put(p, :first_name, first_name)
                      end
                      case Map.fetch(params, "last_name") do
                        :error ->
                          ""
                        {:ok, last_name} ->
                            p = Map.put(p, :last_name, last_name)
                      end

                      case Storage.update_existent(:users, [id, p]) do
                        {:error, _} ->
                          result_500(conn)
                        {:not_found, _} ->
                          result_404(conn,%{})
                        _ ->
                          result_200(conn,%{})
                      end
                    else
                      result_400(conn, %{})
                    end
                end
              "locations" ->
                case Storage.find(:locations,id) do
                  [] ->
                    result_404(conn, %{})
                  _ ->
                    if not_nil?(params, "distance") && not_nil?(params, "country") && not_nil?(params, "city") && not_nil?(params, "place") do
                      p = %{}
                      p = case Map.fetch(params, "distance") do
                        :error ->
                          p
                        {:ok, distance} ->
                          Map.put(p, :distance, distance)
                      end
                      p = case Map.fetch(params, "country") do
                        :error ->
                          p
                        {:ok, country} ->
                          Map.put(p, :country, country)
                      end
                      p = case Map.fetch(params, "city") do
                        :error ->
                          p
                        {:ok, city} ->
                          Map.put(p, :city, city)
                      end
                      p = case Map.fetch(params, "place") do
                        :error ->
                          p
                        {:ok, place} ->
                          Map.put(p, :place, place)
                      end

                      case Storage.update_existent(:locations, [id, p]) do
                        {:error, _} ->
                          result_500(conn)
                        {:not_found, _} ->
                          result_404(conn,%{})
                        _ ->
                          result_200(conn,%{})
                      end

                    else
                      result_400(conn, %{})
                    end
                end

              "visits" ->
                case Storage.find(:visits,id) do
                  [] ->
                    result_404(conn, %{})
                  _ ->
                    if not_nil?(params, "user") && not_nil?(params, "location") && not_nil?(params, "visited_at") && not_nil?(params, "mark") do

                      p = %{}
                      case Map.fetch(params, "user") do
                        :error ->
                          ""
                        {:ok, val} ->
                            p = Map.put(p, :user, val)
                      end
                      case Map.fetch(params, "location") do
                        :error ->
                          ""
                        {:ok, val} ->
                            p = Map.put(p, :location, val)
                      end
                      case Map.fetch(params, "visited_at") do
                        :error ->
                          ""
                        {:ok, val} ->
                            p = Map.put(p, :visited_at, val)
                      end
                      case Map.fetch(params, "mark") do
                        :error ->
                          ""
                        {:ok, val} ->
                            p = Map.put(p, :mark, val)
                      end

                      case Storage.update_existent(:visits, [id, p]) do
                        {:error, _} ->
                          result_500(conn)
                        {:not_found, _} ->
                          result_404(conn,%{})
                        _ ->
                          result_200(conn,%{})
                      end
                    else
                      result_400(conn, %{})
                    end
                end
              _ ->
                result_404(conn, %{})
            end
        end
      end

    else
      result_404(conn, %{})
    end

  end

  def int_if_exist?(map, key) do
    case Map.fetch(map, key) do
      :error ->
        true
      {:ok, nil} ->
        false
      {:ok, val} ->
        case Integer.parse(val) do
          {_int, ""} ->
            true
          {_,_} ->
            false
          :error ->
            false
        end
    end
  end

  def not_nil?(map, key) do
    case Map.fetch(map, key) do
      :error ->
        true
      {:ok, nil} ->
        false
      {:ok, _} ->
        true
    end

  end

  def new_record(conn, params) do

    type = Map.get(params, "type")

    case type do
      "users" ->
          if not_nil?(params, "id") && not_nil?(params, "birth_date") && not_nil?(params,  "email") && not_nil?(params,  "gender") && not_nil?(params, "first_name") && not_nil?(params, "last_name")  do
            p = Map.put(%{}, :id, Map.get(params, "id"))
            p = Map.put(p, :birth_date, Map.get(params, "birth_date"))
            p = Map.put(p, :email, Map.get(params, "email") )
            p = Map.put(p, :gender, Map.get(params, "gender") )
            p = Map.put(p, :first_name, Map.get(params, "first_name"))
            p = Map.put(p, :last_name, Map.get(params, "last_name") )

            result =  Storage.create_new(:users, {p[:id], p[:birth_date], p[:email],p[:gender],p[:first_name],p[:last_name]})

            if result do
              result_200(conn,%{})
            else
              result_400(conn, %{})
            end
          else
            result_400(conn, %{})
          end
      "locations" ->
          if not_nil?(params, "id") && not_nil?(params, "distance") && not_nil?(params, "country") && not_nil?(params, "city") && not_nil?(params, "place") do
            p = Map.put(%{}, :id, Map.get(params, "id"))
            p = Map.put(p, :distance, Map.get(params, "distance"))
            p = Map.put(p, :country, Map.get(params, "country") )
            p = Map.put(p, :city, Map.get(params, "city"))
            p = Map.put(p, :place, Map.get(params, "place") )

            result =  Storage.create_new(:locations, {p[:id], p[:distance], p[:country],p[:city],p[:place]})

            if result do
              result_200(conn,%{})
            else
              result_400(conn, %{})
            end
          else
            result_400(conn, %{})
          end

      "visits" ->
        if not_nil?(params, "id") && not_nil?(params, "user") && not_nil?(params, "location") && not_nil?(params, "visited_at") && not_nil?(params, "mark") do
          p = Map.put(%{}, :id, Map.get(params, "id"))
          p = Map.put(p, :user, Map.get(params, "user"))
          p = Map.put(p, :location, Map.get(params, "location") )
          p = Map.put(p, :visited_at, Map.get(params, "visited_at"))
          p = Map.put(p, :mark, Map.get(params, "mark") )

          result = Storage.create_new(:visits, {p[:id], p[:user], p[:location],p[:visited_at],p[:mark]})

          if result do
            result_200(conn,%{})
          else
            result_400(conn, %{})
          end
        else
          result_400(conn, %{})
        end
      _ ->
        result_404_empty(conn)
    end

  end

  defp get_int_or_nil_from(params, name) do
    case Map.get(params, name) do
      nil ->
        nil
      from ->
        Logger.debug "получена следующая строка #{from}"
        case Integer.parse(from) do
          {fromI, _} ->
            fromI
          :error ->
            nil
        end
    end
  end

  def result_200(conn,object) do
    conn
    |> put_status(200)
    |> json(object)
  end

  def result_400(conn, object) do
    conn
    |> put_status(400)
    |> json(object)
  end

  def result_404(conn, object) do

    conn
    |> put_status(404)
    |> json(object)
  end

  def result_404_empty(conn) do
    # Logger.debug "попытка отправить пустой ответ"
    conn
    |> put_status(404)

  end

  def result_500(conn) do
    conn
    |> put_status(500)
    |> json(%{})
  end

end
