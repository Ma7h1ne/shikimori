json.array! @collection.reverse do |entry|
  name = (
    entry.russian if params[:search].present? && params[:search].fix_encoding.contains_russian?
  ) || entry.name

  json.data entry.id
  json.value name
  json.label render('suggest', entry: entry, entry_name: name)
end
