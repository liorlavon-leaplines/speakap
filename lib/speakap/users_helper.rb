# Reusable code for Speakap users

module SpeakapUsersHelper
  # @param [Object] u Speakap User object
  def self.update_user(u, network)
    user = User.find_or_initialize_by(speakap_eid: u['EID']) do |new_user|
      new_user.email = "#{u['EID']}@speakap.com" # u['primaryEmail']
      new_user.password = SecureRandom.hex
    end

    user.first_name = u['name']['firstName']
    user.last_name = (u['name']['infix'] + ' ' + u['name']['familyName']).strip
    user.avatar = u['avatarThumbnailUrl']

    # Organizations (can be unset if the speakap environment is not enterprise)
    if u['_embedded'] && u['_embedded']['organizationGroups']
      groups = u['_embedded']['organizationGroups']
      user.business_unit_primary = groups[0]['name'] unless groups[0].nil?
      user.business_unit_secondary = groups[1]['name'] unless groups[1].nil?
    end

    user.save!

    network.members.find_or_create_by!(user: user)

    user
  end
end
