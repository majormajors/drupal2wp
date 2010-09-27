require "rubygems"
require "bundler/setup"
require "active_record"
require "yaml"

D2W_CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), "database.yml"))

module Drupal
  class Base < ::ActiveRecord::Base
    establish_connection(D2W_CONFIG["drupal"])
  end
  
  class Node < Base
    set_table_name "node"
    set_primary_key "nid"
    has_many :revisions, :foreign_key => "nid", :class_name => "NodeRevision"
    has_many :comments, :foreign_key => "nid"
    belongs_to :user, :foreign_key => "uid"
    
    scope :posts, where(:node_type => "news")
    scope :pages, where(:node_type => "page")
    scope :wiki_pages, where(:node_type => "wiki_page")
  end
  
  class Comment < Base
    set_table_name "comments"
    set_primary_key "cid"
    belongs_to :node, :foreign_key => "nid"
    belongs_to :user, :foreign_key => "uid"
  end
  
  class NodeRevision < Base
    set_table_name "node_revisions"
    set_primary_key "vid"
    belongs_to :node, :foreign_key => "nid"
  end
  
  class User < Base
    set_table_name "users"
    set_primary_key "uid"
    has_many :nodes, :foreign_key => "uid"
    has_many :comments, :foreign_key => "uid"
  end
end

module Wordpress
  class Base < ::ActiveRecord::Base
    establish_connection(D2W_CONFIG["wordpress"])
  end
  
  class Post < Base
    set_table_name "wp_posts"
    set_primary_key "ID"
    has_many :comments, :foreign_key => "comment_post_ID"
    has_many :revisions, :foreign_key => "post_parent", :class_name => "PostRevision"
    
    after_create do
      guid = "http://localhost:8888/?p=#{self.ID}"
      save
    end
    
    default_scope where(:post_type => "post", :post_parent => 0)
  end
  
  class PostRevision < Base
    set_table_name "wp_posts"
    set_primary_key "ID"
    belongs_to :post, :foreign_key => "post_parent"
    
    after_create do
      guid = "http://localhost:8888/?p=#{self.ID}"
      save
    end
    
    default_scope where(:post_type => "revision")
  end
  
  class Comment < Base
    set_table_name "wp_comments"
    set_primary_key "comment_ID"
    belongs_to :post, :foreign_key => "comment_post_ID"
  end
end

