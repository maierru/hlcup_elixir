defmodule Hlcup.Scanner do
  require Logger
  alias Hlcup.Storage
  @folder "/opt/app/data"

  def init(_, _opts) do
    Storage.init()
    scan_folder()
  end

  def scan_folder() do
    case File.ls(@folder) do
      {:ok, files} ->
        Logger.debug files |> Enum.join(" ")
        iterate(files)
      _ ->
       Logger.warn "Нет файлов"
    end
  end

  def iterate([fl | tail]) do
    Logger.debug "обработка файла #{fl}"
    # "locations_1.json" => ["locations", "1"]
    [ f | _num] = fl |> String.slice(0..-6) |> String.split("_")
    case f do
      "locations" ->
        Logger.debug "обработка locations"

        case get_structure(fl) do
          {:ok, structure} ->
            Logger.debug "сохраняем locations в ets"
            save_locations(Map.get(structure, "locations"))
          {:error, desc} ->
            Logger.debug desc
        end
      "users" ->
        Logger.debug "обработка users #{fl}"

        case get_structure(fl) do
          {:ok, structure} ->
            Logger.debug "сохраняем locations в ets"
            save_users(Map.get(structure, "users"))
          {:error, desc} ->
            Logger.debug desc
        end
      "visits" ->
        Logger.debug  "обработка visits #{fl}"

        case get_structure(fl) do
          {:ok, structure} ->
            Logger.debug "сохраняем visits в ets"
            save_visits(Map.get(structure, "visits"))
          {:error, desc} ->
            Logger.debug desc
        end

      _ ->
        Logger.warn "не известный формат файла #{fl}"
    end

    # TODO: Task
    iterate(tail)

  end

  def iterate([]) do
    "end"
  end

  def get_structure(file) do
    Logger.debug "Попытка распарсить файл #{file}"
    case File.read("#{@folder}/#{file}") do
      {:ok, binary_text} ->
        Logger.debug "Содержимое файла получено."
        case parse_json(binary_text) do
          %{} = structure ->
            Logger.debug "Получена структура - возвращаем"
            {:ok, structure}
          err ->
            Logger.debug err
            {:error, "Не удалось распарсить json file"}
        end
      _other ->
        Logger.debug "Не удалось прочитать содержимое файла"
    end
  end

  def parse_json(text) do
    Poison.decode!(text)
  end

  def save_locations([loc | other]) do
    # %{"city" => "Лейпатск", "country" => "Камбоджа","distance" => 80, "id" => 1, "place" => "Речка"}
    %{"city" => city, "country" => country, "distance" => distance, "id" => id, "place" => place} = loc
    Logger.debug "сохраняем location с id: #{id}"
    Storage.create_object(:locations, {id,distance,country,city,place})
    # TODO: Task
    save_locations(other)
  end

  def save_locations([]) do
    Logger.debug "done locations."
  end

  def save_users([user | other]) do
    # %{"birth_date" => -74908800, "email" => "omrorethacahraas@yandex.ru", "first_name" => "Арина", "gender" => "f", "id" => 1, "last_name" => "Хопетасян"}
    %{"first_name" => first_name, "last_name" => last_name, "birth_date" => birth_date, "gender" => gender, "id" => id, "email" => email} = user
    Logger.debug "сохраняем user с id: #{id}"
    Storage.create_object(:users, {id,birth_date,email,gender,first_name,last_name})
    # TODO: Task
    save_users(other)
  end

  def save_users([]) do
    Logger.debug "done users."
  end

  def save_visits([visit | other]) do
    # {"user" => 69, "location" => 68, "visited_at" => 1081505959, "id" => 1, "mark" => 1}
    %{"user" => user, "location" => location, "visited_at" => visited_at, "id" => id, "mark" => mark} = visit
    Logger.debug "сохраняем visit с id: #{id}"
    Storage.create_object(:visits, {id,user,location,visited_at,mark})
    # TODO: Task
    save_visits(other)
  end

  def save_visits([]) do
    Logger.debug "done visits."
  end

end
