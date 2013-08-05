class User < ActiveRecord::Base
  attr_accessor :overwrite, :upload
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
     
  has_many :contacts
  has_many :fields
  
  accepts_nested_attributes_for :fields, allow_destroy: true, reject_if: Proc.new { |f| f[:title].blank? }
  
  has_attached_file :file,
                    :path  => Rails.env.development? || Rails.env.test? ? "#{Rails.root}/uploads/:user_id/:hash.:extension" : "/home/deployer/apps/touchbase/shared/uploads/:user_id/:hash.:extension",
                    :url => "/uploads/:user_id/:hash.:extension",
                    :hash_secret => "R3sadkfasd8fkj8k0a8dfyh3jr23uy32r3j2j23hlk3j"
  
  Paperclip.interpolates :user_id do |file, style|
    file.instance.id
  end

  before_validation :set_step
  validate :requires_import, unless: Proc.new { |u| u.new_record? || u.has_pending_import? }
  after_save :sidekiq_blob_import, if: Proc.new { |u| u.upload && !u.blob.blank? }
  after_save :sidekiq_file_import, if: Proc.new { |u| u.upload && u.file.exists? }
  
  def requires_import
    if step == 1
      self.errors.add :base, "You must upload contacts to use the system."
    end
  end
  
  def set_step
    self.overwrite ||= false
    if !has_pending_import? && contacts.empty?
      self.step = 1
    elsif fields.empty?
      self.step = 2
    elsif true # NO FOLLOWUPS
      self.step = 3
    else
      self.step = 4
    end
  end
  
  def sidekiq_blob_import
    if self.update_column :import_progress, 0
      ImportWorker.perform_async id, "blob", overwrite
    end
  end
  
  def sidekiq_file_import
    if self.update_column :import_progress, 0
      ImportWorker.perform_async id, "file", overwrite
    end
  end
  
  def import_blob(overwrite)
    i = Importer.new(id, "blob", overwrite)
    self.update_column :import_progress, 0
    
    if i.import
      self.blob = nil
      self.import_progress = 100
      self.save
      i.delete_file
    end
  end
  
  def import_file(overwrite)
    i = Importer.new(id, "file", overwrite)
    self.update_column :import_progress, 0
    
    if i.import
      self.file.clear
      self.import_progress = 100
      self.save
    end
  end
  
  def save_contact(args = {})
    name = args.delete(:name)
    c = contacts.where(name: name).first
    
    if c
      c.update_attributes args
    else
      c = contacts.create name: name, data: args[:data]
    end

    c
  end
  
  def has_pending_import?
    file.exists? || !blob.blank?
  end
  
  def create_headers
    headers = []
    
    if has_pending_import?
      unless blob.blank?
        i = Importer.new(id, "blob")
        
        if i.headers
          i.headers.map { |h| headers.push h }
          i.create_headers
        end
        
        i.delete_file
      end
      
      if file.exists?
        i = Importer.new(id, "file")
        
        if i.headers
          i.headers.map { |h| headers.push h } 
          i.create_headers
        end
      end
      
      if headers.empty?
        false
      end
    else
      false
    end
  end
end
