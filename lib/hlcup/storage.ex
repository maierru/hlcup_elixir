defmodule Hlcup.Storage do
  require Logger

  @hardcoded_date {2017,8,28,0,30,3}

  {year,month,day, hour, minute, sec} = case File.read("/tmp/data/options.txt") do
    {:ok, file} ->
      case file |> String.split() |> Enum.map(&String.to_integer(&1)) do
        [now_timestamp, _state] ->
          case DateTime.from_unix(now_timestamp) do
            {:ok, %DateTime{year: year, month: month, day: day, hour: hour, minute: minute, second: sec}} ->
              {year, month, day, hour, minute, sec}
            _ ->
              @hardcoded_date
          end
        _ ->
          Logger.error "Can't parse /tmp/data/options.txt"
          @hardcoded_date
      end
    _ ->
      @hardcoded_date
  end

  @now_year year
  @now_month month
  @now_day day
  @now_hour hour
  @now_minute minute
  @now_sec sec

  @location_table :locations
  @user_table :users
  @visit_table :visits
  @user_visits :user_visits
  @location_visits :location_visits

  def current_date() do
    {@now_year, @now_month, @now_day, @now_hour, @now_minute, @now_sec}
  end

  def init() do
    :ets.new(@location_table, [:ordered_set, :public, :named_table, {:read_concurrency,true}, {:write_concurrency,true}]) # , {:write_concurrency,true}
    Logger.debug "ETS :locations created"
    :ets.new(@user_table, [:ordered_set, :public, :named_table, {:read_concurrency,true}, {:write_concurrency,true}]) # , {:write_concurrency,true}
    Logger.debug "ETS :users created"
     :ets.new(@visit_table, [:ordered_set, :public, :named_table, {:read_concurrency,true}, {:write_concurrency,true}]) # , {:write_concurrency,true}
    Logger.debug "ETS :visits created"
    :ets.new(@user_visits, [:bag, :public, :named_table, {:read_concurrency,true}, {:write_concurrency,true}]) # , {:write_concurrency,true}
    Logger.debug "ETS :user_visits created"
    :ets.new(@location_visits, [:bag, :public, :named_table, {:read_concurrency,true}, {:write_concurrency,true}]) # , {:write_concurrency,true}
    Logger.debug "ETS :location_visits created"
  end

  def create_object(table, object) do
    case table do
      :locations ->
        :ets.insert(@location_table, object)
      :users ->
        :ets.insert(@user_table, object)
      :visits ->
        {id,user,location,_visited_at,_mark} = object
        :ets.insert(@visit_table, object)
        :ets.insert(@user_visits, {user,id})
        :ets.insert(@location_visits, {location,id})
      _ ->
        Logger.error "Неизвестная таблица для сохранения"
    end

  end

  def find(type, id) do
    case type do
      :locations ->
        :ets.lookup(@location_table, id)
      :users ->
        :ets.lookup(@user_table, id)
      :visits ->
        :ets.lookup(@visit_table, id)
      _ ->
        Logger.debug "Неизвестные параметры поиска"
        {:error, "Не заданный тип для поиска объекта"}
    end
  end


  def update_existent(type, [id, object]) do
    case type do
      :locations ->
        case find(type, id) do
          [{_id,_distance,_country,_city,_place}] ->
            # %{k: v, k1: v1} = object
            Enum.each object, fn {k,v} ->
              case k do
                :distance ->
                  :ets.update_element(@location_table, id, {2, v})
                :country ->
                  :ets.update_element(@location_table, id, {3, v})
                :city ->
                  :ets.update_element(@location_table, id, {4, v})
                :place ->
                  :ets.update_element(@location_table, id, {5, v})
                key ->
                  Logger.warn "неизвестный ключ для обновления - locations/#{id} #{key}"
                  false
              end
            end
          [] ->
            {:not_found, "Not found location"}
        end
      :users ->
        case find(type, id) do
          [{_id,_birth_date,_email,_gender,_first_name,_last_name}] ->
            # %{k: v, k1: v1} = object
            Enum.each object, fn {k,v} ->
              case k do
                :birth_date ->
                  :ets.update_element(@user_table, id, {2, v})
                :email ->
                  :ets.update_element(@user_table, id, {3, v})
                :gender ->
                  :ets.update_element(@user_table, id, {4, v})
                :first_name ->
                  :ets.update_element(@user_table, id, {5, v})
                :last_name ->
                  :ets.update_element(@user_table, id, {6, v})
                key ->
                  Logger.warn "неизвестный ключ для обновления - user/#{id} #{key}"
                  false
              end
            end
          [] ->
            {:not_found, "Not found user"}
        end
      :visits ->
        case find(type, id) do
          [{_id,user,location,_visited_at,_mark}] ->
            # %{k: v, k1: v1} = object
            Enum.each object, fn {k,v} ->
              case k do
                :user ->
                  :ets.update_element(@visit_table, id, {2, v})
                  :ets.delete_object(@user_visits, {user,id})
                  :ets.insert(@user_visits, {v,id})
                :location ->
                  :ets.update_element(@visit_table, id, {3, v})
                  :ets.delete_object(@location_visits, {location,id})
                  :ets.insert(@location_visits, {v,id})
                :visited_at ->
                  :ets.update_element(@visit_table, id, {4, v})
                :mark ->
                  :ets.update_element(@visit_table, id, {5, v})
                key ->
                  Logger.warn "неизвестный ключ для обновления - visits/#{id} #{key}"
                  false
              end
            end
          [] ->
            {:not_found, "Not found visit"}
        end
      _ ->
        Logger.debug "Неизвестные параметры поиска"
        {:error, "Неизвестный тип объекта для обновления"}
    end
  end

  def create_new(type, object) do

    case type do
      :locations ->
        :ets.insert_new(@location_table, object)
      :users ->
        Logger.debug "Обновление пользователя"
        :ets.insert_new(@user_table, object)
      :visits ->
        {id,user,location,_visited_at,_mark} = object
        :ets.insert(@visit_table, object)
        :ets.insert(@user_visits, {user,id})
        :ets.insert(@location_visits, {location,id})
      _ ->
        Logger.error "Неизвестные параметры для создания записи"
        false
    end

  end


  # Hlcup.Storage.find_users_visits(80,{:from_date, 934070400})
  # => [[4, 80, 66, 1127200818, 4], [140, 80, 13, 1253036409, 1],
  # [305, 80, 49, 1408682309, 3], [456, 80, 40, 1234621183, 4],
  # [479, 80, 70, 1009949835, 4], [568, 80, 75, 1325483572, 1],
  # [685, 80, 19, 1163450029, 2], [713, 80, 68, 1090741378, 3],
  # [1044, 80, 48, 1384400662, 3], [1235, 80, 59, 1179216200, 1],
  # [1441, 80, 164, 1334962087, 1], [1448, 80, 1, 968827541, 2],
  # [2169, 80, 90, 1295028538, 3], [3098, 80, 128, 1251057605, 1],
  # [3307, 80, 246, 1047721378, 4], [4111, 80, 225, 1373592543, 2],
  # [4352, 80, 214, 1340491860, 4], [5529, 80, 30, 1359437194, 2],
  # [7005, 80, 428, 1216899235, 2], [7764, 80, 38, 1188221098, 4],
  # [7828, 80, 271, 1151025314, 4], [8489, 80, 101, 1220978248, 1]]
  #
  # Hlcup.Storage.find_users_visits(585,{:to_date, 1022716800})
  # => [[6076, 585, 180, 974302199, 4]]
  def find_users_visits(user_id, visited_at) do
    case find(:users, user_id) do
      [_user] ->
        # {id,birth_date,email,gender,first_name,last_name} = user
        visit_ids = :ets.lookup(:user_visits,user_id) |> Enum.map(fn({_,visit_id}) -> visit_id end)
        # visit_ids = :ets.lookup(:user_visits,475422) |> Enum.map(fn({_,visit_id}) -> visit_id end)
        # => [7701343, 4900032, 6840698, 4968401, 9659045, 6978489, 5719429, 6664262, 9396431, 6199945]
        case visit_ids do
          [] ->
            []
          _ ->
            # fun =
            visits = visit_ids |> Enum.flat_map(fn (visit_id) -> Hlcup.Storage.find(:visits,visit_id) end)

            case visited_at do
              [nil,nil] ->
                Logger.debug "Поиск всех визитов пользователя #{user_id}"
                # :ets.match_object(:visits, {:'_',id,:'_',:'_',:'_'})
                # fun = :ets.fun2ms(fn {id, user, location, visited_at, mark} when user == 1 -> id end)
                # [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:==, :"$2", user_id}], [:"$$"]}]
                visits
              [unixtime,nil] ->
                Logger.debug "Поиск всех визитов пользователя #{user_id} после #{unixtime}"
                # fun = :ets.fun2ms(fn {id, user, location, visited_at, mark} when user == 80 and visited_at > 934070400 -> id end
                # [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:andalso, {:==, :"$2", user_id}, {:>, :"$4", unixtime}}], [:"$$"]}]
                visits |> Enum.filter( fn({_id, _user, _location, visited_at, _mark}) ->  visited_at > unixtime end)
              [nil, unixtime]  ->
                Logger.debug "Поиск всех визитов пользователя #{user_id} до #{unixtime}"
                [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:andalso, {:==, :"$2", user_id}, {:<, :"$4", unixtime}}], [:"$$"]}]
                visits |> Enum.filter( fn({_id, _user, _location, visited_at, _mark}) ->  visited_at < unixtime end)
              [unixtime1,unixtime2] ->
                Logger.debug "Поиск всех визитов пользователя #{user_id} от #{unixtime1} до #{unixtime2}"
                # [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:andalso, {:andalso, {:==, :"$2", user_id}, {:>, :"$4", unixtime1}}, {:<, :"$4", unixtime2}}], [:"$$"]}]
                visits |> Enum.filter( fn({_id, _user, _location, visited_at, _mark}) ->  visited_at > unixtime1 && visited_at < unixtime2 end)
              end
          # Logger.debug fun
          # :ets.select(:visits, fun)
        end

      [] ->
        Logger.debug "Пользователь не найден"
        {:user_not_found, "Пользователь не найден"}
      _ ->
        Logger.debug "Ошибка поиска пользователя"
        {:error, "Ошибка поиска пользователя"}
    end

  end

  def find_users_visits_with_locations(user_id, visited_at, loc_params ) do

    case find_users_visits(user_id, visited_at) do
      {:user_not_found, "Пользователь не найден"} ->
        {:user_not_found, "Пользователь не найден"}
      {:error, "Ошибка поиска пользователя"} ->
        {:error, "Ошибка поиска пользователя"}
      visits_list ->
        case loc_params do
            [nil, nil] ->
              Logger.debug "поиск без страны и расстояния до города"
              visits_list
            [country,nil] ->
              Logger.debug "поиск в стране #{country}"
              visits_list |> Enum.filter(fn({_id,_user,locationid,_visitid_at,_mark}) -> located?(locationid,[country, nil]) end)
            [nil,toDistance] ->
              Logger.debug "поиск с расстоянием до города #{toDistance}"
              visits_list |> Enum.filter(fn({_id,_user,locationid,_visitid_at,_mark}) -> located?(locationid,[nil, toDistance]) end)
            [country,toDistance] ->
              Logger.debug "поиск в стране #{country} и с расстоянием до города #{toDistance}"
              visits_list |> Enum.filter(fn({_id,_user,locationid,_visitid_at,_mark}) -> located?(locationid,[country, toDistance]) end)
        end
        |> sort_visits_by_visit()
    end

  end

  def located?(locationid,[country, toDistance])  do
    # Logger.debug "Фильтрация"
    case find(:locations, locationid) do
      [{_,thisdistance,thiscountry,_,_}] ->
        case [country, toDistance] do
          [nil,nil] -> true
          [country, nil] ->
            country == thiscountry
          [nil, toDistance] ->
            thisdistance < toDistance
          [country, toDistance] ->
            country == thiscountry && thisdistance < toDistance
        end
      [] -> false
      _ ->
        Logger.error "Ошибка поиска по locationid: #{locationid}"
        false
    end
  end

  def sort_visits_by_visit(visits_list) do
    # сортирует по дате возрастания события
    # visits_list |> Enum.map(&(List.to_tuple(&1))) |> List.keysort(3)
    visits_list |> List.keysort(3)
  end

  def get_visits_by_locations_and_times(locationid, visited_at \\ [nil,nil]) do

    case find(:locations, locationid) do
      [{_id,_distance,_country,_city,_place}] ->
        visit_ids = :ets.lookup(:location_visits,locationid) |> Enum.map(fn({_,visit_id}) -> visit_id end)

        case visit_ids do
          [] ->
            []
          _ ->
            visits = visit_ids |> Enum.flat_map(fn (visit_id) -> Hlcup.Storage.find(:visits,visit_id) end)

            # fun =
            case visited_at do
              [nil,nil] ->
                # :ets.fun2ms(fn {id, user, location, visited_at, mark} when location == 1 -> id end)
                # [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:==, :"$3", locationid}], [:"$$"]}]
                visits
             [unixtime,nil] ->
                # fun = :ets.fun2ms(fn {id, user, location, visited_at, mark} when location == 1 and visited_at > 934070400 -> id end
                # [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:andalso, {:==, :"$3", locationid}, {:>, :"$4", unixtime}}], [:"$$"]}]
                visits |> Enum.filter( fn({_id, _user, _location, visited_at, _mark}) ->  visited_at > unixtime end)
              [nil, unixtime]  ->
                # [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:andalso, {:==, :"$3", locationid}, {:<, :"$4", unixtime}}], [:"$$"]}]
                visits |> Enum.filter( fn({_id, _user, _location, visited_at, _mark}) ->  visited_at < unixtime end)
              [unixtime1, unixtime2] ->
                Logger.debug "Поиск всех визитов visits: #{locationid} от #{unixtime1} до #{unixtime2}"
                # [{{:"$1", :"$2", :"$3", :"$4", :"$5"}, [{:andalso, {:andalso, {:==, :"$3", locationid}, {:>, :"$4", unixtime1}}, {:<, :"$4", unixtime2}}], [:"$$"]}]
                visits |> Enum.filter( fn({_id, _user, _location, visited_at, _mark}) ->  visited_at > unixtime1 && visited_at < unixtime2 end)
            end
        end



        # Hlcup.Storage.get_visits_by_locations_and_times(581, [1413072000, 810345600])
        # {id,user,location,visited_at,mark}
        # => [[7978, 156, 459, 1027035196, 1], [9457, 869, 459, 1010786881, 3]]
        # :ets.select(:visits, fun)

      [] ->
        {:not_found, "Место не найдено"}
    end

  end

  def location_average_point(locationid, [from_date: from_date, to_date: to_date, fromAge: fromAge, toAge: toAge, gender: gender]) do

    case get_visits_by_locations_and_times(locationid, [from_date,to_date]) do
      {:not_found, "Место не найдено"} ->
        {:not_found, "Место не найдено"}
      [] -> 0
      this ->
        result = this
        |> Enum.filter(fn({_id,userid,_locationid,_visitid_at,mark}) -> mark != nil && profiled?(userid,[fromAge, toAge, gender]) end)
        |> Enum.map(fn({_,_,_,_,mark}) -> mark end) |> Enum.reduce({0,0}, fn(x, {sum, count}) -> {sum+x, count+1} end)

        case result do
          {_sum, 0} -> 0
          # TODO: /locations/413/avg?toAge=62 странно округляет
          {sum, count} -> sum / count |> Float.round(5)
        end
    end

  end

  def profiled?(userid,[fromAge, toAge, gender]) do

    # {{y, m, d}, h} = (NaiveDateTime.utc_now |> NaiveDateTime.to_erl)

    case find(:users, userid) do
      [{_id,nil,_email,_thisgender,_first_name,_last_name}] ->
        false
      [{_id,birth_date,_email,thisgender,_first_name,_last_name}] ->
        case [fromAge, toAge, gender] do
          [nil,nil,nil] ->
            true
          [nil,to,nil] ->
            # {:ok, to_naivedatetime_ago} = ({{y-to, m, d}, h} |> NaiveDateTime.from_erl)
            # {:ok, datetime} = DateTime.from_unix(birth_date)
            # to_naivedatetime_ago < DateTime.to_naive(datetime)
            years(birth_date) < to
          [nil,nil,g] ->
            g == thisgender
          [nil,to,g] ->
            years(birth_date) < to && g == thisgender
          [from,nil,nil] ->
            # {:ok, from_naivedatetime_ago} = ({{y-from, m, d}, h} |> NaiveDateTime.from_erl)
            # {:ok, datetime} = DateTime.from_unix(birth_date)
            # from_naivedatetime_ago > DateTime.to_naive(datetime)
            from <= years(birth_date)
          [from,to,nil] ->
            # {:ok, from_naivedatetime_ago} = ({{y-from, m, d}, h} |> NaiveDateTime.from_erl)
            # {:ok, to_naivedatetime_ago} = ({{y-to, m, d}, h} |> NaiveDateTime.from_erl)
            # {:ok, datetime} = DateTime.from_unix(birth_date)

            # from_naivedatetime_ago > DateTime.to_naive(datetime) && to_naivedatetime_ago < DateTime.to_naive(datetime)
            from <= years(birth_date) && years(birth_date) < to
          [from,nil,g] ->
            # {:ok, from_naivedatetime_ago} = ({{y-from, m, d}, h} |> NaiveDateTime.from_erl)
            # {:ok, datetime} = DateTime.from_unix(birth_date)

            # from_naivedatetime_ago > DateTime.to_naive(datetime) && g == thisgender
            from <= years(birth_date) && g == thisgender
          [from,to,g] ->
            # {:ok, from_naivedatetime_ago} = ({{y-from, m, d}, h} |> NaiveDateTime.from_erl)
            # {:ok, to_naivedatetime_ago} = ({{y-to, m, d}, h} |> NaiveDateTime.from_erl)

            # {:ok, datetime} = DateTime.from_unix(birth_date)
            # from_naivedatetime_ago > DateTime.to_naive(datetime) && to_naivedatetime_ago < DateTime.to_naive(datetime) && g == thisgender
            from <= years(birth_date) && years(birth_date) < to && g == thisgender
        end
      [] ->
        Logger.info "Присутствует пользователь, которого нет в списке пользователей, но присутствует в списке визитов"
        false
    end
  end

  # => 0..100
  def years(timestamp) do
    {:ok, %DateTime{year: year,month: month, day: day, hour: hour, minute: minute, second: second}} = DateTime.from_unix(timestamp)
    case month do
      m when m > @now_month ->
        @now_year-1-year
      m when m == @now_month ->
        case day do
          d when d > @now_day ->
            @now_year-1-year
          d when d == @now_day ->
            case hour do
              h when h > @now_hour ->
                @now_year-1-year
              h when h == @now_hour ->
                case minute do
                  min when min > @now_minute ->
                    @now_year-1-year
                  min when min == @now_minute ->
                    case second do
                      sec when sec > @now_sec ->
                        @now_year-1-year
                      sec when sec <= @now_sec ->
                        @now_year-year
                    end
                  min when min < @now_minute ->
                    @now_year-year
                end
              h when h < @now_hour ->
                @now_year-year
            end
          d when d < @now_day ->
            @now_year-year
        end
      m when m < @now_month ->
        @now_year-year
    end
  end

  def destroy_all() do
    :ets.delete(@location_table)
    :ets.delete(@user_table)
    :ets.delete(@visit_table)
  end

end
