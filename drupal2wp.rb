$: << File.expand_path(File.dirname(__FILE__))
require "model"

Drupal::Node.posts.each do |drupal_post|
  base_rev = drupal_post.revisions.order("timestamp").first
  post = Wordpress::Post.create({
    :post_author => 1,
    :post_name => drupal_post.title.parameterize,
    :post_date => Time.at(drupal_post.created),
    :post_date_gmt => Time.at(drupal_post.created).getutc,
    :post_modified => Time.at(drupal_post.updated),
    :post_modified_gmt => Time.at(drupal_post.updated).getutc,
    :post_title => drupal_post.title,
    :post_content => base_rev.body
  })
  
  drupal_post.revisions.order("timestamp").each do |sub_rev|
    rev_time = Time.at(sub_rev.timestamp)
    rev_time_utc = rev_time.getutc
    post.revisions.create({
      :post_author => 1,
      :post_name => "#{post.id}-revision",
      :post_date => rev_time,
      :post_date_gmt => rev_time_utc,
      :post_modified => rev_time,
      :post_modified_gmt => rev_time_utc,
      :post_title => sub_rev.title,
      :post_content => sub_rev.body
    })
    post.update_attributes({
      :post_modified => rev_time,
      :post_modified_gmt => rev_time_utc,
      :post_title => sub_rev.title,
      :post_content => sub_rev.body,
      :post_excerpt => sub_rev.teaser
    })
  end if drupal_post.revisions.count > 1
  
  drupal_post.comments.each do |comment|
    comment_time = Time.at(comment.timestamp)
    post.comments.create({
      :comment_author => comment.name,
      :comment_author_email => comment.user.mail,
      :comment_author_IP => comment.hostname,
      :comment_date => comment_time,
      :comment_date_gmt => comment_time.getutc,
      :comment_content => comment.comment
    })
    
    post.comment_count += 1
    post.save
  end
end
