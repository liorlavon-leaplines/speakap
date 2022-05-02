require 'speakap/users_helper'

namespace :speakap_users do
  desc 'Speakap users'
  include SpeakapUsersHelper

  task import: :environment do
    Network.where.not(speakap_app_id: nil).each do |network|

      puts network.name + ': '

      api = network.speakap
      total = 0
      page = 1

      # Import users
      loop do
        users = api.get_users(page)
        break if users.empty?
        # Save the users
        users.each do |u|
          SpeakapUsersHelper.update_user(u, network)
        end
        total += users.count
        page += 1
      end
      puts "- #{total} users were imported"

      # Set the admins
      admin_ids = api.get_admins.map { |a| a['EID'] }
      User.where(speakap_eid: admin_ids).update_all(admin: true)
      puts "- #{admin_ids.count} admins were assigned"

      # Update Groups
      network.users.update_all(groups: [])
      total = 0
      page = 1
      loop do
        groups = api.get_groups(page)
        break if groups.empty?

        groups.each do |group|
          eids = group['_embedded']['members'].map { |u| u['EID'] }
          User.where(speakap_eid: eids).update_all("groups = groups || '{#{groups[0]['name']}}'")
        end

        total += groups.count
        page += 1
      end
      puts "- #{total} groups were imported"

    end
  end
end


