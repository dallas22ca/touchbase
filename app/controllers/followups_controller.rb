class FollowupsController < ApplicationController
  before_action :set_followup, only: [:show, :edit, :update, :destroy]
  
  def index
    @followups = current_user.followups
    redirect_to new_followup_path if @followups.empty?
  end
  
  # GET /followups/1
  # GET /followups/1.json
  def show
  end

  # GET /followups/new
  def new
    @followup = Followup.new(recurrence: 3.months, description: "Touch base with {{contact.name}}")
  end

  # GET /followups/1/edit
  def edit
    @criteria = @followup.criteria
  end

  # POST /followups
  # POST /followups.json
  def create
    @signup_complete = true if current_user.step == 4
    @followup = current_user.followups.new(followup_params)
    parse_criteria(@followup)
    
    respond_to do |format|
      if @followup.save
        if @signup_complete
          redirect = tasks_path
        else
          redirect = followups_path
        end
        
        format.html { redirect_to redirect, notice: 'Followup was successfully created.' }
        format.json { render action: 'show', status: :created, location: @followup }
      else
        format.html { render action: 'new' }
        format.json { render json: @followup.errors, status: :unprocessable_entity }
      end
    end
  end
  
  
  # PATCH/PUT /followups/1
  # PATCH/PUT /followups/1.json
  def update
    parse_criteria(@followup)
    
    respond_to do |format|
      @followup.assign_attributes(followup_params)
      
      if @followup.save
        format.html { redirect_to followups_path, notice: 'Followup was successfully updated.' }
        format.json { head :no_content }
        format.js
      else
        format.html { render action: 'edit' }
        format.json { render json: @followup.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /followups/1
  # DELETE /followups/1.json
  def destroy
    @followup.destroy
    respond_to do |format|
      format.html { redirect_to followups_url }
      format.json { head :no_content }
    end
  end
  
private
  
  def set_followup
    @followup = current_user.followups.find(params[:id])
  end
  
  def followup_params
    params.require(:followup).permit(:offset, :description, :field_id, :recurrence)
  end
  
end
