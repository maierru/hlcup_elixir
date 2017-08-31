defmodule Hlcup.ScannerMemory do
  require Logger
  alias Hlcup.Storage
  @zipfile '/tmp/data/data.zip'


  def start_link(_,_) do
    init(1,1)
  end

  def init(_,_) do
    Storage.init()

    case :zip.extract(@zipfile, [:memory]) do

      {:ok, files} ->
        # Enum.each(files, fn(x) -> saveinfo(x) end )
        Logger.info "Асинхронная загрузка файлов"
        # Logger.info Time.utc_now()
        Task.async_stream(files, fn(x) -> saveinfo(x) end, [timeout: 55000]) |> Enum.map(fn(result) -> result end)
      _ ->
        Logger.error "Не удалось извлечь из зип архива в память"
    end

    # info = :ets.i()
    # Logger.error info

  end

  def saveinfo({filename, data}) do
    Logger.info "Processing #{filename}"
    [ f | _num] = filename |> :binary.list_to_bin |> String.slice(0..-6) |> String.split("_")
    case f do
      "locations" ->
        case parse_json(data) do
          %{} = structure ->
            # Logger.debug "Получена структура - возвращаем"
             save_locations(Map.get(structure, "locations"))
          err ->
            Logger.error err
            {:error, "Не удалось распарсить json file"}
        end
      "users" ->
        case parse_json(data) do
          %{} = structure ->
            # Logger.debug "Получена структура - возвращаем"
             save_users(Map.get(structure, "users"))
          err ->
            Logger.error err
            {:error, "Не удалось распарсить json file"}
        end
      "visits" ->
        case parse_json(data) do
          %{} = structure ->
            # Logger.debug "Получена структура - возвращаем"
             save_visits(Map.get(structure, "visits"))
          err ->
            Logger.error err
            {:error, "Не удалось распарсить json file"}
        end
      _ ->
        :ok
    end
  end

  def parse_json(text) do
    Poison.decode!(text)
  end

  def save_locations([loc | other]) do
    # %{"city" => "Лейпатск", "country" => "Камбоджа","distance" => 80, "id" => 1, "place" => "Речка"}
    # %{"city" => city, "country" => country, "distance" => distance, "id" => id, "place" => place} = loc

    p = Map.put(%{}, :id, Map.get(loc, "id"))
    p = Map.put(p, :city, Map.get(loc, "city"))
    p = Map.put(p, :country, Map.get(loc, "country") )
    p = Map.put(p, :distance, Map.get(loc, "distance"))
    p = Map.put(p, :place, Map.get(loc, "place") )

    # Logger.debug "сохраняем location с id: #{p[:id]}"
    # Storage.create_object(:locations, {id,distance,country,city,place})
    Storage.create_object(:locations, {p[:id], p[:distance], p[:country],p[:city],p[:place]})
    # TODO: Task
    save_locations(other)
  end

  def save_locations([]) do
    # Logger.debug "done locations."
  end

  def save_users([user | other]) do
    # %{"birth_date" => -74908800, "email" => "omrorethacahraas@yandex.ru", "first_name" => "Арина", "gender" => "f", "id" => 1, "last_name" => "Хопетасян"}
    # %{"first_name" => first_name, "last_name" => last_name, "birth_date" => birth_date, "gender" => gender, "id" => id, "email" => email} = user

    p = Map.put(%{}, :id, Map.get(user, "id"))
    p = Map.put(p, :first_name, Map.get(user, "first_name"))
    p = Map.put(p, :last_name, Map.get(user, "last_name") )
    p = Map.put(p, :birth_date, Map.get(user, "birth_date"))
    p = Map.put(p, :gender, Map.get(user, "gender") )
    p = Map.put(p, :email, Map.get(user, "email") )

    # result =  Storage.create_new(:users, )

    # Logger.debug "сохраняем user с id: #{p[:id]}"
    # Storage.create_object(:users, {id,birth_date,email,gender,first_name,last_name})
    Storage.create_object(:users, {p[:id], p[:birth_date], p[:email],p[:gender],p[:first_name],p[:last_name]})
    # TODO: Task
    save_users(other)
  end

  def save_users([]) do
    # Logger.debug "done users."
  end

  def save_visits([visit | other]) do
    # {"user" => 69, "location" => 68, "visited_at" => 1081505959, "id" => 1, "mark" => 1}
    # %{"user" => user, "location" => location, "visited_at" => visited_at, "id" => id, "mark" => mark} = visit

    p = Map.put(%{}, :id, Map.get(visit, "id"))
    p = Map.put(p, :user, Map.get(visit, "user"))
    p = Map.put(p, :location, Map.get(visit, "location") )
    p = Map.put(p, :visited_at, Map.get(visit, "visited_at"))
    p = Map.put(p, :mark, Map.get(visit, "mark") )

    # Logger.debug "сохраняем visit с id: #{p[:id]}"
    # Storage.create_object(:visits, {id,user,location,visited_at,mark})
    Storage.create_object(:visits, {p[:id], p[:user], p[:location],p[:visited_at],p[:mark]})
    # TODO: Task
    save_visits(other)
  end

  def save_visits([]) do
    # Logger.debug "done visits."
  end

end
