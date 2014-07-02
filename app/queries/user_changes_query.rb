class UserChangesQuery
  def initialize entry, field
    @entry = entry
    @field = field.to_s
  end

  def fetch
    UserChange
      .where(item_id: @entry.id, model: @entry.class.name, column: @field)
      .where(status: [UserChangeStatus::Pending, UserChangeStatus::Taken, UserChangeStatus::Accepted])
      .includes(:user)
      .includes(:approver)
      .order(created_at: :desc)
  end

  def authors with_taken = true
    fetch
      .where(status: with_taken ? [UserChangeStatus::Taken, UserChangeStatus::Accepted] : [UserChangeStatus::Accepted])
      .map(&:user)
      .uniq
  end

  def lock
    UserChange
      .where(model: @entry.class.name, item_id: @entry.id, status: UserChangeStatus::Locked)
      .includes(:user)
      .first
  end
end
