require "hbc/utils/ls_quarantine/database"
require "hbc/utils/ls_quarantine/extended_attribute"

module LSQuarantine
  module_function

  def add(file, type: nil, app_name: nil, title: nil, url: nil, status: ExtendedAttribute::QUARANTINE_TYPES[:unopened], database_path: nil)
    attribute = ExtendedAttribute.new(file)
    database  = Database.new(database_path)

    uuid = database.generate_uuid

    timestamp = Time.now

    database_entry = {
      "LSQuarantineTypeNumber" => type,
      "LSQuarantineAgentName" => app_name,
      "LSQuarantineEventIdentifier" => uuid,
      "LSQuarantineTimeStamp" => timestamp,
      "LSQuarantineOriginTitle" => title,
      "LSQuarantineOriginURLString" => url,
    }

    attribute.set(status, timestamp, agent: app_name, event_id: uuid) && database.insert(database_entry)
  end

  def remove(file, database_path: nil)
    attribute = LSQuarantine::ExtendedAttribute.new(file)
    database  = LSQuarantine::Database.new(database_path)

    attribute_hash = attribute.get

    return true if attribute_hash.nil?

    uuid = attribute_hash["event_identifier"]

    attribute.remove && database.delete(uuid)
  end
end
