class BbCodes::RepliesTag
  include Singleton
  include Translation

  REGEXP = /
    (?<tag>
      (?<brs> \n|<br>)*
      \[
        replies=(?<ids> [\d,]+ )
      \]
    )
  /mx
  DISPLAY_LIMIT = 100

  def format text
    text.gsub REGEXP do |matched|
      ids = comment_ids $~[:ids].split(',')
      replies = ids.map {|id| "[comment=#{id}][/comment]" }.join(', ')

      "<div class=\"b-replies#{' single' if ids.one?}\" " +
        "data-reply-text=\"#{i18n_t 'reply'}\" " +
        "data-replies-text=\"#{i18n_t 'replies'}\">#{replies}</div>" if ids.any?
    end
  end

private

  def comment_ids ids
    Comment
      .where(id: ids)
      .order(:id)
      .limit(DISPLAY_LIMIT)
      .pluck(:id)
  end
end
