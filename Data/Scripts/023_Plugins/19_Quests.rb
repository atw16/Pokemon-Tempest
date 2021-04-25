##########################################################################
#                   SIMPLE QUEST SYSTEM + UI 1.0
#                           by mej 71
#
# updated for pokemon essentials 17.2, bug fixes
# and integration to pause menu by derFischae
##########################################################################
=begin
This is a fairly comprehensive, yet easy to use system + UI
for managing quests in your fangame

Features
    Support for up to 10 stages per quest
    Complex rewards
    Very detailed compiler errors, tells you exactly what you've messed up
    Doesn't save quest data for player (similar to how other objects are handled in Essentials, non-specific data is stored in a separate data file so that quest info is updated for old saves)
    Plug and play
    Won't break old save files by adding this script
    Easy to edit and create new quests

Installation:
Add quests.txt to your PBS folder
Add the 'Quest UI' folder to Graphics/Pictures (be sure to include the folder itself, not just the contents)
Add this text from questScript.txt into a new section above the Main but below the Compiler section
And that's all there is to the installation

How to Use
Start of a new game is not required,
should integrate into old saves files

There's a few methods you will need to know to use the quest system
(you will activate/complete/fail quests within your events,
only you know in which context to do so)
Code:
    activateQuest(id)
    completeQuest(id)
    failQuest(id)
    advanceQuestToStage(questID, stageNum)
In all of these, 'id' and 'questID' refer to the ID of the desired quest,
which is defined in quests.txt, the file you added to your PBS folder.
The name of the quest can also be used in as the 'id' for these methods,
since quest names are unique.
The 'stageNum' refers to the desired stage number of that quest.
Be sure the id you input exists,
as there is currently no check against it

Editing the Quest PBS file:
There's only 8 types of lines in the PBS that you need to know
    Name - This is the name of the quest that will be displayed. Names must be unique (two quests cannot share a name)
    Stage1 - This is the description of the current task of the quests. Each quest can have up to 10 stages (so Stage2, Stage9, etc are also valid). Stages must be listed in order, no skipping numbers.
    Reward - This is the reward given to the player upon completion. When completion is triggered, it will read the string assigned and evaluate it as code. So if you make your reward "Kernel.pbMessage('Hello')", upon completion it will display a message saying "Hello". This reward is fairly simple, but keep in mind any type of code can be run here, so you can give items, set variables, or pretty much anything else you can code. Note that this code is not tested, so test all your rewards to ensure you didn't make errors. (Pro tip: semi-colons can be used to separate multiple instructions in a single line of code)
    RewardDescription - A description of the reward, so they player may determine whether or not to pursue
    QuestDescription - A description of the quest
    StageLocation1 - Same as with Stage1, there are up to 10 locations supported. This tells the player where to go for the next task. Can either be the desired map name or map id. These are checked upon compile time to ensure the map exists. "nil" can be used if you don't want to specify a map
    CompleteMessage - The "Result" description displayed in the UI for a completed quest.
    FailedMessage - The "Result" description displayed in the UI for a failed quest.
=end
PluginManager.register({
  :name => "Simple Quest UI",
  :version => "1.0",
  :credits => "mej 71, derFischae",
  :link => "https://www.pokecommunity.com/showthread.php?t=429037"
})
#========================================================
#This class holds the information for an individual quest
#========================================================
class Quest
  attr_reader   :id
  attr_reader   :stage

  def stage=(value)
    if value>$quest_data.getMaxStagesForQuest(@id)
      value = $quest_data.getMaxStagesForQuest(@id)
    end
    @stage = value
  end

  def initialize(id)
    @id         = id
    @stage      = 1
  end
end

#========================================================
#This class holds all the trainers quests
#========================================================
class Player_Quests
  attr_accessor :active_quests
  attr_accessor :completed_quests
  attr_accessor :failed_quests
  attr_accessor :selected_quest_id

  def initialize
    @active_quests =[]
    @completed_quests = []
    @failed_quests = []
    @selected_quest_id = 0
  end

  #questID can either be the internal ID number, or the quest name
  def activateQuest(questID)
    if questID.is_a?(String)
      questID = $quest_data.getIDFromName(questID)
    end
    for i in 0...@active_quests.length
      if @active_quests[i].id==questID
        Kernel.pbMessage("You have already started this quest")
        return
      end
    end
    for i in 0...@completed_quests.length
      if @completed_quests[i].id==questID
        Kernel.pbMessage("You have already complete this quest")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id==questID
        Kernel.pbMessage("You have already failed this quest")
        return
      end
    end
    @active_quests.push(Quest.new(questID))
  end

  def failQuest(questID)
    if questID.is_a?(String)
      questID = $quest_data.getIDFromName(questID)
    end
    found = false
    for i in 0...@completed_quests.length
      if @completed_quests[i].id==questID
        Kernel.pbMessage("You have already complete this quest")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id==questID
        Kernel.pbMessage("You have already failed this quest")
        return
      end
    end
    for i in 0...@active_quests.length
       if @active_quests[i].id==questID
         @failed_quests.push(@active_quests[i])
         @active_quests.delete_at(i)
         found=true
         break
       end
    end
    if !found
      @failed_quests.push(Quest.new(questID))
    end
  end

  def completeQuest(questID)
    if questID.is_a?(String)
      questID = $quest_data.getIDFromName(questID)
    end
    found = false
    for i in 0...@completed_quests.length
      if @completed_quests[i].id==questID
        Kernel.pbMessage("You have already completed this quest")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id==questID
        Kernel.pbMessage("You have already failed this quest")
        return
      end
    end
    for i in 0...@active_quests.length
       if @active_quests[i].id==questID
         @completed_quests.push(@active_quests[i])
         @active_quests.delete_at(i)
         found = true
         break
       end
    end
    if !found
      @completed_quests.push(Quest.new(questID))
    end
  end

  def advanceQuestToStage(questID,stageNum)
    if questID.is_a?(String)
      questID = $quest_data.getIDFromName(questID)
    end
    found = false
    for i in 0...@active_quests.length
       if @active_quests[i].id==questID
         @active_quests[i].stage=stageNum
         found = true
       end
       return if found
    end
    if !found
      quest = Quest.new(questID)
      quest.stage = stageNum
      @active_quests.push(quest)
    end
  end
end

class PokemonGlobalMetadata
  def quests
    @quests = Player_Quests.new if !@quests
    return @quests
  end

  alias quest_init initialize
  def initialize
    quest_init
    @quests = Player_Quests.new
  end
end

def activateQuest(id)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.activateQuest(id)
end

def completeQuest(id)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.completeQuest(id)
end

def failQuest(id)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.failQuest(id)
end

def advanceQuestToStage(questID,stageNum)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.advanceQuestToStage(questID,stageNum)
end

QUEST_FILE_NAME = "quests.txt"  #the name of the file to read from

#========================================================
#a module use during compilation of the quest file
#========================================================
module QuestsData
  NeededInfo={
     "Name"=>[1,"s"],
     "Stage1"=>[2,"s"],
     "Stage2"=>[3,"s"],
     "Stage3"=>[4,"s"],
     "Stage4"=>[5,"s"],
     "Stage5"=>[6,"s"],
     "Stage6"=>[7,"s"],
     "Stage7"=>[8,"s"],
     "Stage8"=>[9,"s"],
     "Stage9"=>[10,"s"],
     "Stage10"=>[11,"s"],
     "QuestDescription"=>[12,"s"],
     "StageLocation1" => [13,"v|s"],
     "StageLocation2" => [14,"v|s"],
     "StageLocation3" => [15,"v|s"],
     "StageLocation4" => [16,"v|s"],
     "StageLocation5" => [17,"v|s"],
     "StageLocation6" => [18,"v|s"],
     "StageLocation7" => [19,"v|s"],
     "StageLocation8" => [20,"v|s"],
     "StageLocation9" => [21,"v|s"],
     "StageLocation10" => [22,"v|s"],
     "CompletedMessage"=>[23,"s"],
     "FailedMessage"=>[24,"s"],
  }
end

#========================================================
#Pseudo class to read quest info from
#========================================================
class QuestInfo
  attr_reader :id
  attr_reader :name
  attr_reader :stages
  attr_reader :questDesc
  attr_reader :locations
  attr_reader :completedMessage
  attr_reader :failedMessage

  def initialize(id,questName,stages,questDesc,locations,completedMessage,failedMessage)
    @id = id
    @name = questName
    @stages = stages
    @questDesc = questDesc
    @locations = locations
    @completedMessage = completedMessage
    @failedMessage = failedMessage
  end
end

#=====================================================================
#This class loads/reads all data for all quests.  Updates at the start
#of every game session will use this class to determine their values,
#and this is used for deciding updates/rewards, etc
#=====================================================================
class Game_Quests
  def initialize
    needCompile = false
    latestdatatime = 0
    latesttexttime = 0
    if !safeExists?("Data/Quests.rxdata")
      needCompile = true
    else
        File.open("Data/Quests.rxdata"){|file|
               latestdatatime=[latestdatatime,file.mtime.to_i].max
        }
        File.open("PBS/#{QUEST_FILE_NAME}"){|file|
             latesttexttime=[latesttexttime,file.mtime.to_i].max
        }
        needCompile=true if latesttexttime>=latestdatatime
        needCompile=true if Input.press?(Input::CTRL)
    end
    if $DEBUG && safeExists?("PBS/#{QUEST_FILE_NAME}") && needCompile
      compileAllQuests
    else
      begin
        @all_quests = load_data("Data/Quests.rxdata")
      rescue
        @all_quests = []
        Kernel.pbMessage("No quests data found")
      end
    end
  end

  def compileAllQuests
    #names and IDs must be unique
    checkQuestIDs=[]
    checkQuestNames=[]
    @all_quests = []
    currentQuest = 0
    name = ""
    stages = []
    questDesc = ""
    completedMessage = ""
    failedMessage = ""
    locations = []
    lineCount = 0
    #check order of stages
    curStage = 0
    curLocation = 0
    pbCompilerEachCommentedLine("PBS/"+QUEST_FILE_NAME) {|line,lineno|
     lineCount+=1
     if line[/^\s*\[\s*(\d+)\s*\]\s*$/]
       if currentQuest>0
         if stages.length==0
           raise _INTL("Expected at least one stage for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
         end
         if locations.length!=stages.length
           raise _INTL("Expected the number of locations to match the number of stages for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
         end
         if questDesc.nil? || questDesc==""
           raise _INTL("Expected a quest description for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
         end
         if completedMessage.nil? || completedMessage==""
           raise _INTL("Expected a completed message for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
         end
         if failedMessage.nil? || failedMessage==""
           raise _INTL("Expected a failed message for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
         end
         @all_quests.push(QuestInfo.new(currentQuest,name,stages,questDesc,locations,completedMessage,failedMessage))
         curStage = 0
         curLocation = 0
         name = ""
         stages = []
         locations = []
         questDesc = ""
         completedMessage = ""
         failedMessage = ""
       end
       sectionname=$~[1]
       if checkQuestIDs.include?(sectionname.to_i)
           raise _INTL("Quest numbers must be unique! {1} already used\r\n{2}",sectionname,FileLineData.linereport)
       end
       currentQuest=sectionname.to_i
       checkQuestIDs.push(currentQuest)
     else
       if currentQuest==0
         raise _INTL("Expected a section at the beginning of the file\r\n{1}",FileLineData.linereport)
       end
       if !line[/^\s*(\w+)\s*=\s*(.*)$/]
         raise _INTL("Bad line syntax (expected syntax like XXX=YYY)\r\n{1}",FileLineData.linereport)
       end
       matchData=$~
       schema=nil
       FileLineData.setSection(currentQuest,matchData[1],matchData[2])
       schema=QuestsData::NeededInfo[matchData[1]]
       schemaValues = schema[1]
       if schema
         schemaValues = schema[1].split('|')
       end
       if schema
         for i in 0...schemaValues.length
           schema[1] = schemaValues[i]
           record=pbGetCsvRecord(matchData[2],lineno,schema) rescue next
           case schema
           when QuestsData::NeededInfo["Name"]
             if checkQuestNames.include?(record)
                 raise _INTL("Quest names must be unique! {1} already used\r\n{2}",record,FileLineData.linereport)
             end
             name = record
             checkQuestNames.push(name)
             break
           when QuestsData::NeededInfo["QuestDescription"]
             questDesc = record
             break
           when QuestsData::NeededInfo["CompletedMessage"]
             completedMessage = record
             break
           when QuestsData::NeededInfo["FailedMessage"]
             failedMessage = record
             break
           else
             if matchData[1].include?("StageLocation")
               if ((matchData[1][/\d+/]).to_i)!=curLocation+1
                 raise _INTL("Locations need to be in order.  Expecting location {1}\r\n{2}",curLocation+1,FileLineData.linereport)
               end
               if record.is_a?(String) && record.downcase=="nil"
                 curLocation+=1
                 locations.push(record)
                 break
               elsif record !~ /\D/ #only numbers
                 mapname = pbGetMessage(MessageTypes::MapNames,record.to_i) rescue nil
                 if mapname.nil?
                   raise _INTL("Invalid map id for quest {1}, at stage {2}",sectionname,curLocation)
                 end
                 curLocation+=1
                 locations.push(nil)
                 break
               elde
                 mapid = MessageTypes.getFromMapHashValue(MessageTypes::MapNames,record)
                 if mapid.nil?
                   raise _INTL("Invalid map id for quest {1}, at stage {2}",sectionname,curLocation)
                 end
                 curLocation+=1
                 locations.push(mapid)
                 break
               end
             elsif matchData[1].include?("Stage")
               if ((matchData[1][/\d+/]).to_i)!=curStage+1
                 raise _INTL("Stages need to be in order.  Expecting stage {1}\r\n{2}",curStage+1,FileLineData.linereport)
               end
               curStage+=1
               stages.push(record)
               break
             else
               raise _INTL("Unexpected field {1} for quest {2}",matchData[1],sectionname)
             end
           end
         end
       end
     end
   }
    if stages.length==0
      raise _INTL("Expected at least one stage for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
    end
    if locations.length!=stages.length
      raise _INTL("Expected the number of locations to match the number of stages for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
    end
    if questDesc.nil? || questDesc==""
      raise _INTL("Expected a quest description for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
    end
    if completedMessage.nil? || completedMessage==""
      raise _INTL("Expected a completed message for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
    end
    if failedMessage.nil? || failedMessage==""
      raise _INTL("Expected a failed message for quest {1}\r\n{2}",currentQuest,FileLineData.linereport)
    end
    @all_quests.push(QuestInfo.new(currentQuest,name,stages,questDesc,locations,completedMessage,failedMessage)) if lineCount>0
    save_data(@all_quests,"Data/Quests.rxdata")
  end

  def nameAllQuests
    for i in 0...@all_quests.length
      Kernel.pbMessage("#{@all_quests[i].id}")
      Kernel.pbMessage("#{@all_quests[i].name}")
      for j in 0...@all_quests[i].stages.length
        Kernel.pbMessage("#{@all_quests[i].stages[j]}")
      end
      Kernel.pbMessage("#{@all_quests[i].questDesc}")
    end
  end

  def getIDFromName(name)
    for i in 0...@all_quests.length
      return @all_quests[i].id if @all_quests[i].name==name
    end
  end

  def getNameFromID(id)
    for i in 0...@all_quests.length
      return @all_quests[i].name if @all_quests[i].id==id
    end
  end

  def getQuestStages(questID)
    if questID.is_a?(String)
      questID = getIDFromName(questID)
    end
    for i in 0...@all_quests.length
      return @all_quests[i].stages if @all_quests[i].id==questID
    end
  end

  def getQuestDescription(questID)
    if questID.is_a?(String)
      questID = getIDFromName(questID)
    end
    for i in 0...@all_quests.length
      return @all_quests[i].questDesc if @all_quests[i].id==questID
    end
  end

  def getStageLocation(questID,stage)
    if questID.is_a?(String)
      questID = getIDFromName(questID)
    end
    for i in 0...@all_quests.length
      return @all_quests[i].locations[stage-1] if @all_quests[i].id==questID
    end
  end

  def getMaxStagesForQuest(questID)
    if questID.is_a?(String)
      questID = getIDFromName(questID)
    end
    quests = getQuestStages(questID)
    return quests.length
  end

  def getCompletedMessage(questID)
    if questID.is_a?(String)
      questID = getIDFromName(questID)
    end
    for i in 0...@all_quests.length
      return @all_quests[i].completedMessage if @all_quests[i].id==questID
    end
  end

  def getFailedMessage(questID)
    if questID.is_a?(String)
      questID = getIDFromName(questID)
    end
    for i in 0...@all_quests.length
      return @all_quests[i].failedMessage if @all_quests[i].id==questID
    end
  end
end

#========================================================
#modify messages to check for a map name among the maps
#========================================================
class Messages
  def getFromMapHashValue(type,key)
    delayedLoad
    return nil if !@messages
    return nil if !@messages[0]
    return nil if !@messages[0][type] && !@messages[0][0]
    key.sub!("e^","é")
    id=Messages.stringToKey(key)
    if @messages[type] && @messages[type].include?(id)
        return @messages[type].index(id)
    elsif @messages[0] && @messages[0].include?(id)
      return @messages[0].index(id)
    end
    return nil
  end
end

module MessageTypes
  def self.getFromMapHashValue(type,key)
    @@messages.getFromMapHashValue(type,key)
  end
end

$quest_data = Game_Quests.new
#$quest_data.nameAllQuests

QUEST_GRAPHICS_PATH = "Graphics/Pictures/Quest UI/"

class QuestScene
  @@viewingActive = 0
  @@viewingComplete = 0
  @@viewingFailed  = 0

  def update
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @yOffsetInfo=0
    @yOffsetList=0
    @curNumLines=0
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @viewport_text=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport_text.z=99999+1
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap(QUEST_GRAPHICS_PATH+"quest_bg")
    @sprites["background"].zoom_x = Graphics.width/(@sprites["background"].bitmap.width)
    @sprites["background"].zoom_y = Graphics.height/(@sprites["background"].bitmap.height)
    @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["sections_text_overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport_text)
    @sprites["quests_list_overlay"]=BitmapSprite.new(Graphics.width,Graphics.height*4/5,@viewport_text)
    @sprites["quests_list_overlay"].x=5
    @sprites["quests_list_overlay"].y=35
    @sprites["quest_info_overlay"]=BitmapSprite.new(Graphics.width,Graphics.height*4/5-8,@viewport_text)
    @sprites["quest_info_overlay"].y=38
    @sprites["quest_info_overlay"].x=202
    @sprites["navigation_info_overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport_text)
    pbSetSmallFont(@sprites["overlay"].bitmap)
    pbSetSmallFont(@sprites["sections_text_overlay"].bitmap)
    pbSetSmallFont(@sprites["quests_list_overlay"].bitmap)
    pbSetSmallFont(@sprites["quest_info_overlay"].bitmap)
    pbSetSmallFont(@sprites["navigation_info_overlay"].bitmap)
    pbDrawSections
    pbDrawNavigationInfo
  end

  def pbDrawNavigationInfo
    overlay=@sprites["navigation_info_overlay"].bitmap
    overlay.clear
    @sprites["navigation_info_overlay"].bitmap.font.size=20
    baseColor=Color.new(72,72,72)
    shadowColor=Color.new(160,160,160)
    textPositions = [
      ["Arrows - Change Quest/Section",2,Graphics.height-40,0,baseColor,shadowColor],
      ["A,S - Scroll Info",Graphics.width-235,Graphics.height-40,0,baseColor,shadowColor],
      ["X - Exit",Graphics.width-60,Graphics.height-40,0,baseColor,shadowColor],
    ]
    pbDrawTextPositions(overlay,textPositions)
  end

  def pbDrawSections
    @activeQuests=$PokemonGlobal.quests.active_quests
    @completedQuests=$PokemonGlobal.quests.completed_quests
    @failedQuests=$PokemonGlobal.quests.failed_quests
    @sections=[]
    @sections.push([0,_INTL("Active")]) #if @activeQuests.length>0
    @sections.push([1,_INTL("Completed")]) #if @completedQuests.length>0
    @sections.push([2,_INTL("Failed")]) #if @failedQuests.length>0
    @@viewingActive = @activeQuests[0].id if @activeQuests!=[] && @@viewingActive<=0
    @@viewingComplete = @completedQuests[0].id if @completedQuests!=[] && @@viewingComplete<=0
    @@viewingFailed  = @failedQuests[0].id if @failedQuests!=[] && @@viewingFailed<=0
    baseColor=Color.new(72,72,72)
    selectedColor=Color.new(0,0,139)
    shadowColor=Color.new(160,160,160)
    selectedShadowColor=Color.new(160,160,160)
    bitmap = @sprites["sections_text_overlay"].bitmap
    bitmap.clear
    textPositions=[]
    for i in 0...@sections.length
      @sprites["section_icon_#{i}"]=IconSprite.new(0,0,@viewport)
      @sprites["section_icon_#{i}"].setBitmap(QUEST_GRAPHICS_PATH+"section_bar")
      @sprites["section_icon_#{i}"].x=20+(160*i)
      @sprites["section_icon_#{i}"].y=12
      @sprites["section_icon_#{i}"].zoom_x=2
      @sprites["section_icon_#{i}"].zoom_y=2
      if @sections[i][0]==$PokemonGlobal.selectedSection
        @sprites["section_icon_#{i}"].src_rect.set(@sprites["section_icon_#{i}"].bitmap.width/2,0,@sprites["section_icon_#{i}"].bitmap.width/2,@sprites["section_icon_#{i}"].bitmap.height)
      else
        @sprites["section_icon_#{i}"].src_rect.set(0,0,@sprites["section_icon_#{i}"].bitmap.width/2,@sprites["section_icon_#{i}"].bitmap.height)
      end
      if @sections[i][0]==$PokemonGlobal.selectedSection
        textPositions.push([@sections[i][1],85+(160*i),10,2,selectedColor,selectedShadowColor])
      else
        textPositions.push([@sections[i][1],85+(160*i),10,2,baseColor,shadowColor])
      end
    end
    pbDrawTextPositions(bitmap,textPositions)
    pbDrawQuestsList
  end

  def getSelectedID
    questOptions=[@activeQuests,@completedQuests,@failedQuests]
    quests = questOptions[$PokemonGlobal.selectedSection]
    selectionOptions=[@@viewingActive,@@viewingComplete,@@viewingFailed]
    questFound = false
    for i in 0...quests.length
      if quests[i].id==selectionOptions[$PokemonGlobal.selectedSection]
        questFound = true
        break
      end
    end
    if selectionOptions[$PokemonGlobal.selectedSection]<0
      questFound = false
    end
    if !questFound
      case $PokemonGlobal.selectedSection
      when 0
        @@viewingActive = quests[0].id
        selectedID = @@viewingActive
      when 1
        @@viewingComplete = quests[0].id
        selectedID = @@viewingComplete
      when 2
        @@viewingFailed = quests[0].id
        selectedID = @@viewingFailed
      end
    else
      selectedID = selectionOptions[$PokemonGlobal.selectedSection]
    end
    return [quests,selectedID]
  end

  def pbDrawQuestsList
    overlay=@sprites["quests_list_overlay"].bitmap
    overlay.clear
    ret = getSelectedID
    quests = ret[0]
    selectedID = ret[1]
    textPositions = []
    baseColor=Color.new(72,72,72)
    selectedColor=Color.new(0,0,139)
    shadowColor=Color.new(160,160,160)
    selectedShadowColor=Color.new(160,160,160)
    for i in 0...quests.length
      if quests[i].id==selectedID
        textPositions.push([$quest_data.getNameFromID(quests[i].id),0,@yOffsetList+2+(i*31),0,selectedColor,selectedShadowColor])
      else
        textPositions.push([$quest_data.getNameFromID(quests[i].id),0,@yOffsetList+2+(i*31),0,baseColor,shadowColor])
      end
    end
    pbDrawTextPositions(overlay,textPositions)
    pbDrawQuestInfo
  end

  def pbDrawQuestInfo
    overlay=@sprites["quest_info_overlay"].bitmap
    overlay.clear
    ret = getSelectedID
    quests = ret[0]
    selectedID = ret[1]
    textPositions = []
    baseColor=Color.new(12,12,12)
    shadowColor=Color.new(72,72,72)
    titleColor = Color.new(135,206,250)
    titleShadow = Color.new(0,0,0, 100)
    selectedColor=Color.new(200,200,200)
    @curNumLines=1
    for i in 0...quests.length
      if quests[i].id==selectedID
        questDescArr = $quest_data.getQuestDescription(quests[i].id).wordwrap(33)
        stages = $quest_data.getQuestStages(quests[i].id)
        if stages[quests[i].stage-1]
          stageDescArr = (stages[quests[i].stage-1]).wordwrap(30)
        else
          stageDescArr=[]
        end
        textPositions.push([$quest_data.getNameFromID(quests[i].id),(Graphics.width-200)/2,@yOffsetInfo,2,titleColor,titleShadow])
        @curNumLines+=1
        for j in 0...questDescArr.length
          textPositions.push([_INTL("{1}",questDescArr[j]),0,@yOffsetInfo+20+20*j,0,baseColor,shadowColor])
          @curNumLines+=1
        end
         #What's draw depends on if completed, failed, or active
        if $PokemonGlobal.selectedSection==2
          textPositions.push([_INTL("Result:"),0,@yOffsetInfo+20+20*questDescArr.length,0,selectedColor,shadowColor])
          textPositions.push([_INTL(" {1}",$quest_data.getFailedMessage(quests[i].id).wordwrap(30)),0,@yOffsetInfo+40+20*questDescArr.length,0,baseColor,shadowColor])
          @curNumLines+=1
          break
        elsif $PokemonGlobal.selectedSection==1
          textPositions.push([_INTL("Result:"),0,@yOffsetInfo+20+20*questDescArr.length,0,selectedColor,shadowColor])
          textPositions.push([_INTL(" {1}",$quest_data.getCompletedMessage(quests[i].id).wordwrap(30)),0,@yOffsetInfo+40+20*questDescArr.length,0,baseColor,shadowColor])
          @curNumLines+=1
          break
        else
          textPositions.push([_INTL("Next Task:"),0,@yOffsetInfo+20+20*(questDescArr.length+1),0,selectedColor,shadowColor])
          @curNumLines+=1
          textPositions.push([_INTL(" {1}",stageDescArr[0]),0,@yOffsetInfo+40+20*(questDescArr.length+1),0,baseColor,shadowColor])
          @curNumLines+=1
          for k in 1...stageDescArr.length
            textPositions.push([_INTL("{1}",stageDescArr[k]),0,@yOffsetInfo+40+20*(questDescArr.length+1)+20*k,0,baseColor,shadowColor])
            @curNumLines+=1
          end
          if $quest_data.getStageLocation(quests[i].id,quests[i].stage).to_s=="nil"
            locationText = "No location available"
          else
            ret=pbGetMessage(MessageTypes::MapNames,$quest_data.getStageLocation(quests[i].id,quests[i].stage))
            if $Trainer
              ret.gsub!(/\\PN/,$Trainer.name)
            end
            locationText = ret
          end
          textPositions.push([_INTL("Next Location:"),0,@yOffsetInfo+40+20*(questDescArr.length)+20*(stageDescArr.length+1),0,selectedColor,shadowColor])
          @curNumLines+=1
          textPositions.push([_INTL(" {1}",locationText),0,@yOffsetInfo+60+20*(questDescArr.length)+20*(stageDescArr.length+1),0,baseColor,shadowColor])
          @curNumLines+=1
          break
        end
      end
    end
    pbDrawTextPositions(overlay,textPositions)
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      self.update
      if Input.trigger?(Input::B) #X, exit from scene
        break
      end
      #change selected list
      if Input.trigger?(Input::LEFT)
        @yOffsetInfo=0
        @yOffsetList=0
        for i in 0...@sections.length
          if $PokemonGlobal.selectedSection==@sections[i][0]
            pos = i
            break
          end
        end
        pos-=1
        if pos<0
          pos = @sections.length-1
        end
        $PokemonGlobal.selectedSection = @sections[pos][0]
        pbDrawSections
      elsif Input.trigger?(Input::RIGHT)
        @yOffsetInfo=0
        @yOffsetList=0
        for i in 0...@sections.length
          if $PokemonGlobal.selectedSection==@sections[i][0]
            pos = i
            break
          end
        end
        pos+=1
        if pos>=@sections.length
          pos = 0
        end
        $PokemonGlobal.selectedSection = @sections[pos][0]
        pbDrawSections
      #Scroll quest info up/down
      elsif Input.trigger?(Input::R)  #S
        if (@yOffsetInfo/-20)<(@curNumLines-14)
          @yOffsetInfo-=20
          pbDrawQuestInfo
        end
      elsif Input.trigger?(Input::L) #A
        if @yOffsetInfo<0
          @yOffsetInfo+=20
          pbDrawQuestInfo
        end
      #move up/down list of quests
      elsif Input.trigger?(Input::DOWN)
        @yOffsetInfo=0
        nextQuest = -1
        #if nextQuest remains -1, then there are no quests to list
        case $PokemonGlobal.selectedSection
        when 0
          for i in 0...@activeQuests.length
             if @activeQuests[i].id==@@viewingActive
               nextQuest = i+1
               break
             end
          end
          if nextQuest>-1
            if nextQuest>=@activeQuests.length
              @@viewingActive=@activeQuests[0].id
              @yOffsetList=0
            else
              @@viewingActive = @activeQuests[nextQuest].id
              if (@yOffsetList/-31)<@activeQuests.length-10
                @yOffsetList-=31
              end
            end
          end
        when 1
          for i in 0...@completedQuests.length
             if @completedQuests[i].id==@@viewingComplete
               nextQuest = i+1
               break
             end
          end
          if nextQuest>-1
            if nextQuest>=@completedQuests.length
              @@viewingComplete=@completedQuests[0].id
              @yOffsetList=0
            else
              @@viewingComplete = @completedQuests[nextQuest].id
              if (@yOffsetList/-31)<@completedQuests.length-6
                @yOffsetList-=31
              end
            end
          end
        when 2
          for i in 0...@failedQuests.length
             if @failedQuests[i].id==@@viewingFailed
               nextQuest = i+1
               break
             end
          end
          if nextQuest>-1
            if nextQuest>=@failedQuests.length
              @@viewingFailed=@failedQuests[0].id
              @yOffsetList=0
            else
              @@viewingFailed = @failedQuests[nextQuest].id
              if (@yOffsetList/-31)<@failedQuests.length-6
                @yOffsetList-=31
              end
            end
          end
        end
        pbDrawQuestsList
      elsif Input.trigger?(Input::UP)
        @yOffsetInfo=0
        nextQuest = -2
        #if nextQuest remains -2, then there are no quests to list
        case $PokemonGlobal.selectedSection
        when 0
          for i in 0...@activeQuests.length
             if @activeQuests[i].id==@@viewingActive
               nextQuest = i-1
               break
             end
          end
          if nextQuest!=-2
            if nextQuest<0
              @@viewingActive=@activeQuests[@activeQuests.length-1].id
              if @activeQuests.length>10
                @yOffsetList=(@activeQuests.length-10)*-31
              end
            else
              @@viewingActive = @activeQuests[nextQuest].id
              if @yOffsetList<0
                @yOffsetList+=31
              end
            end
          end
        when 1
          for i in 0...@completedQuests.length
             if @completedQuests[i].id==@@viewingComplete
               nextQuest = i-1
               break
             end
          end
          if nextQuest!=-2
            if nextQuest<0
              @@viewingComplete=@completedQuests[@completedQuests.length-1].id
              if @completedQuests.length>10
                @yOffsetList=(@completedQuests.length-10)*-31
              end
            else
              @@viewingComplete = @completedQuests[nextQuest].id
              if @yOffsetList<0
                @yOffsetList+=31
              end
            end
          end
        when 2
          for i in 0...@failedQuests.length
             if @failedQuests[i].id==@@viewingFailed
               nextQuest = i-1
               break
             end
          end
          if nextQuest!=-2
            if nextQuest<0
              @@viewingFailed=@failedQuests[@failedQuests.length-1].id
              if @failedQuests.length>10
                @yOffsetList=(@failedQuests.length-10)*-31
              end
            else
              @@viewingFailed = @failedQuests[nextQuest].id
              if @yOffsetList<0
                @yOffsetList+=31
              end
            end
          end
        end
        pbDrawQuestsList
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class QuestScreen
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbMain
    @scene.pbEndScene
  end
end

def pbViewQuests
  if !hasAnyQuests?
    Kernel.pbMessage(_INTL("You haven't discovered any quests yet"))
    return false
  end
  scene=QuestScene.new
  screen=QuestScreen.new(scene)
  screen.pbStartScreen()
end

#=============================================
#Store currently selected section
#=============================================
class PokemonGlobalMetadata
  attr_writer :selectedSection

  def selectedSection
    @selectedSection = 0 if !@selectedSection
    return @selectedSection
  end

  alias quest_ui_init initialize
  def initialize
    quest_ui_init
    @selectedSection = 0
  end
end

def hasAnyQuests?
  if $PokemonGlobal.quests.active_quests.length >0 ||
      $PokemonGlobal.quests.completed_quests.length>0 ||
      $PokemonGlobal.quests.failed_quests.length>0
    return true
  end
  return false
end

#=============================================
#word wrapping (returns an array of sentence fragments, broken by length)
#words kept together
#requires monospaced font to work properly
#=============================================
class String
  def wordwrap(width)
    return self.scan(/\S.{0,#{width-2}}\S(?=\s|$)|\S+/)
  end
end

#======================================
#adding questmenu to the pause menu
#by replacing old method with this one
#
#added by derFischae
#======================================
class PokemonPauseMenu
    def pbStartPokemonMenu
    pbSetViableDexes
    @scene.pbStartScene
    endscene = true
    commands = []
    cmdPokedex  = -1
    cmdPokemon  = -1
    cmdBag      = -1
    #===============
    #added for questmenu
    cmdQuests   = -1
    #end of changes
    #===============
    cmdTrainer  = -1
    cmdSave     = -1
    cmdOption   = -1
    cmdPokegear = -1
    cmdDebug    = -1
    cmdQuit     = -1
    cmdEndGame  = -1
    if !$Trainer
      if $DEBUG
        Kernel.pbMessage(_INTL("The player trainer was not defined, so the menu can't be displayed."))
        Kernel.pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
      end
      return
    end
    commands[cmdPokedex = commands.length]  = _INTL("Pokédex") if $Trainer.pokedex && $PokemonGlobal.pokedexViable.length>0
    commands[cmdPokemon = commands.length]  = _INTL("Pokémon") if $Trainer.party.length>0
    commands[cmdBag = commands.length]      = _INTL("Bag") if !pbInBugContest?
    #=================================================
    #added for questmenu (quest menu point not visible
    #in pause menu while having no quest)
    commands[cmdQuests = commands.length]   = _INTL("Quests") if hasAnyQuests?
    #end of changes
    #=================================================
    commands[cmdPokegear = commands.length] = _INTL("Pokégear") if $Trainer.pokegear
    commands[cmdTrainer = commands.length]  = $Trainer.name
    if pbInSafari?
      if SAFARISTEPS<=0
        @scene.pbShowInfo(_INTL("Balls: {1}",pbSafariState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Steps: {1}/{2}\nBalls: {3}",
           pbSafariState.steps,SAFARISTEPS,pbSafariState.ballcount))
      end
      commands[cmdQuit = commands.length]   = _INTL("Quit")
    elsif pbInBugContest?
      if pbBugContestState.lastPokemon
        @scene.pbShowInfo(_INTL("Caught: {1}\nLevel: {2}\nBalls: {3}",
           PBSpecies.getName(pbBugContestState.lastPokemon.species),
           pbBugContestState.lastPokemon.level,
           pbBugContestState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Caught: None\nBalls: {1}",pbBugContestState.ballcount))
      end
      commands[cmdQuit = commands.length]   = _INTL("Quit Contest")
    else
      commands[cmdSave = commands.length]   = _INTL("Save") if $game_system && !$game_system.save_disabled
    end
    commands[cmdOption = commands.length]   = _INTL("Options")
    commands[cmdDebug = commands.length]    = _INTL("Debug") if $DEBUG
    commands[cmdEndGame = commands.length]  = _INTL("Quit Game")
    loop do
      command = @scene.pbShowCommands(commands)
      if cmdPokedex>=0 && command==cmdPokedex
        if USE_CURRENT_REGION_DEX
          pbFadeOutIn(99999){
            scene = PokemonPokedex_Scene.new
            screen = PokemonPokedexScreen.new(scene)
            screen.pbStartScreen
            @scene.pbRefresh
          }
        else
          if $PokemonGlobal.pokedexViable.length==1
            $PokemonGlobal.pokedexDex = $PokemonGlobal.pokedexViable[0]
            $PokemonGlobal.pokedexDex = -1 if $PokemonGlobal.pokedexDex==$PokemonGlobal.pokedexUnlocked.length-1
            pbFadeOutIn(99999){
              scene = PokemonPokedex_Scene.new
              screen = PokemonPokedexScreen.new(scene)
              screen.pbStartScreen
              @scene.pbRefresh
            }
          else
            pbFadeOutIn(99999){
              scene = PokemonPokedexMenu_Scene.new
              screen = PokemonPokedexMenuScreen.new(scene)
              screen.pbStartScreen
              @scene.pbRefresh
            }
          end
        end
      elsif cmdPokemon>=0 && command==cmdPokemon
        hiddenmove = nil
        pbFadeOutIn(99999){
          sscene = PokemonParty_Scene.new
          sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
          hiddenmove = sscreen.pbPokemonScreen
          (hiddenmove) ? @scene.pbEndScene : @scene.pbRefresh
        }
        if hiddenmove
          $game_temp.in_menu = false
          Kernel.pbUseHiddenMove(hiddenmove[0],hiddenmove[1])
          return
        end
      elsif cmdBag>=0 && command==cmdBag
        item = 0
        pbFadeOutIn(99999){
          scene = PokemonBag_Scene.new
          screen = PokemonBagScreen.new(scene,$PokemonBag)
          item = screen.pbStartScreen
          (item>0) ? @scene.pbEndScene : @scene.pbRefresh
        }
        if item>0
          Kernel.pbUseKeyItemInField(item)
          return
        end
      #===========================================
      #added for questmenu (quest menu point in
      #pause menu leads to quest menu)
      elsif cmdQuests>=0 && command==cmdQuests
        pbFadeOutIn(99999){
          scene = QuestScene.new
          screen = QuestScreen.new(scene)
          screen.pbStartScreen
          @scene.pbRefresh
        }
      #end of changes
      #===========================================
      elsif cmdPokegear>=0 && command==cmdPokegear
        pbFadeOutIn(99999){
          scene = PokemonPokegear_Scene.new
          screen = PokemonPokegearScreen.new(scene)
          screen.pbStartScreen
          @scene.pbRefresh
        }
      elsif cmdTrainer>=0 && command==cmdTrainer
        pbFadeOutIn(99999){
          scene = PokemonTrainerCard_Scene.new
          screen = PokemonTrainerCardScreen.new(scene)
          screen.pbStartScreen
          @scene.pbRefresh
        }
      elsif cmdQuit>=0 && command==cmdQuit
        @scene.pbHideMenu
        if pbInSafari?
          if Kernel.pbConfirmMessage(_INTL("Would you like to leave the Safari Game right now?"))
            @scene.pbEndScene
            pbSafariState.decision = 1
            pbSafariState.pbGoToStart
            return
          else
            pbShowMenu
          end
        else
          if Kernel.pbConfirmMessage(_INTL("Would you like to end the Contest now?"))
            @scene.pbEndScene
            pbBugContestState.pbStartJudging
            return
          else
            pbShowMenu
          end
        end
      elsif cmdSave>=0 && command==cmdSave
        @scene.pbHideMenu
        scene = PokemonSave_Scene.new
        screen = PokemonSaveScreen.new(scene)
        if screen.pbSaveScreen
          @scene.pbEndScene
          endscene = false
          break
        else
          pbShowMenu
        end
      elsif cmdOption>=0 && command==cmdOption
        pbFadeOutIn(99999){
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen
          pbUpdateSceneMap
          @scene.pbRefresh
        }
      elsif cmdDebug>=0 && command==cmdDebug
        pbFadeOutIn(99999){
          pbDebugMenu
          @scene.pbRefresh
        }
      elsif cmdEndGame>=0 && command==cmdEndGame
        @scene.pbHideMenu
        if Kernel.pbConfirmMessage(_INTL("Are you sure you want to quit the game?"))
          scene = PokemonSave_Scene.new
          screen = PokemonSaveScreen.new(scene)
          if screen.pbSaveScreen
            @scene.pbEndScene
          end
          @scene.pbEndScene
          $scene = nil
          return
        else
          pbShowMenu
        end
      else
        break
      end
    end
    @scene.pbEndScene if endscene
  end
end
