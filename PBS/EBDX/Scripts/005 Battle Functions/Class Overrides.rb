#===============================================================================
#  Quick adjustment to the set picture sprite
#===============================================================================
def setPictureSpriteEB(sprite, picture)
  sprite.visible = picture.visible
  # Set sprite coordinates
  sprite.y = picture.y
  sprite.z = picture.number
  # Set zoom rate, opacity level, and blend method
  sprite.zoom_x = picture.zoom_x / 100.0
  sprite.zoom_y = picture.zoom_y / 100.0
  sprite.opacity = picture.opacity
  sprite.blend_type = picture.blend_type
  # Set rotation angle and color tone
  angle = picture.angle
  sprite.tone = picture.tone
  sprite.color = picture.color
  while angle < 0
    angle += 360
  end
  angle %= 360
  sprite.angle = angle
end
#===============================================================================
#  Quick adjustment to the pause arrow for battle message box
#===============================================================================
class Window_AdvancedTextPokemon
  def battlePause
    @pausesprite.dispose if @pausesprite
    @pausesprite = AnimatedSprite.create("Graphics/EBDX/Pictures/pause", 4, 3)
    @pausesprite.z = 100000
    @pausesprite.visible = false
    @pausesprite.oy = 8
  end
end

alias getFormattedText_ebdx getFormattedText unless defined?(getFormattedText_ebdx)
def getFormattedText(*args)
  args[6] = $forcedLineHeight if $forcedLineHeight
  ret = getFormattedText_ebdx(*args)
  $forcedLineHeight = nil
  return ret
end
#===============================================================================
# override for the wild battle function to allow for species specific BGM
# and transitions
#===============================================================================
alias pbWildBattle_ebdx pbWildBattle unless defined?(pbWildBattle_ebdx)
def pbWildBattle(*args)
  # gets cached data
  data =  EliteBattle.get(:nextBattleData)
  wspecies = (!data.nil? && data.is_a?(Hash) && data.has_key?(:WILD_SPECIES)) ? data[:WILD_SPECIES] : nil
  # loads custom wild battle trigger if data hash for species is defined
  return EliteBattle.wildBattle(wspecies, 1, args[3], args[4]) if wspecies.is_a?(Hash)
  # overrides species and level data if defined
  args[0] = wspecies if !wspecies.nil?
  args[1] = data[:WILD_LEVEL] if !data.nil? && data.is_a?(Hash) && data.has_key?(:WILD_LEVEL)
  # caches species number
  if args[0].is_a?(Numeric)
    EliteBattle.set(:wildSpecies, args[0])
  else
    EliteBattle.set(:wildSpecies, EliteBattle.const(args[0]))
  end
  # try to load the next battle speech
  speech = EliteBattle.getData(EliteBattle.get(:wildSpecies), PBSpecies, :BATTLESCRIPT, (EliteBattle.get(:wildForm) rescue 0))
  EliteBattle.set(:nextBattleScript, speech.to_sym) if !speech.nil?
  # caches species level
  EliteBattle.set(:wildLevel, args[1])
  # starts battle processing
  ret = pbWildBattle_ebdx(*args)
  # returns output
  return ret
end
#===============================================================================
module EBS_ScenePriority
  def self.included base
    base.class_eval do
      attr_accessor :addPriority
      alias pbStartScene_ebdx pbStartScene unless self.method_defined?(:pbStartScene_ebdx)
      def pbStartScene(*args)
        pbStartScene_ebdx(*args)
        @viewport.z += 6 if @addPriority
      end
    end
  end
end
#-------------------------------------------------------------------------------
if defined?(PokemonParty_Scene)
  PokemonParty_Scene.send(:include, EBS_ScenePriority)
end
#-------------------------------------------------------------------------------
if defined?(PokemonScreen_Scene)
  PokemonScreen_Scene.send(:include, EBS_ScenePriority)
end
#===============================================================================
#  Catch rate modifiers
#===============================================================================
module BallHandlers
  #-----------------------------------------------------------------------------
  #  pushes module to class level for aliasing
  #-----------------------------------------------------------------------------
  class << BallHandlers
    alias isUnconditional_ebdx isUnconditional? unless self.method_defined?(:isUnconditional_ebdx)
    alias modifyCatchRate_ebdx modifyCatchRate unless self.method_defined?(:modifyCatchRate_ebdx)
  end
  #-----------------------------------------------------------------------------
  #  catch rate modifiers
  #-----------------------------------------------------------------------------
  def self.isUnconditional?(*args)
    data = EliteBattle.get(:nextBattleData); data = {} if !data.is_a?(Hash)
    return true if data.has_key?(:CATCH_RATE) && data[:CATCH_RATE] == "100%"
    return self.isUnconditional_ebdx(*args)
  end

  def self.modifyCatchRate(*args)
    data = EliteBattle.get(:nextBattleData); data = {} if !data.is_a?(Hash)
    return data[:CATCH_RATE] if data.has_key?(:CATCH_RATE) && data[:CATCH_RATE].is_a?(Numeric)
    return self.modifyCatchRate_ebdx(*args)
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Override for catch prevention
#===============================================================================
class PokeBattle_Battle
  #-----------------------------------------------------------------------------
  #  prevents the catching of Pokemon if CATCH_RATE is less than 0
  #-----------------------------------------------------------------------------
  alias pbThrowPokeBall_ebdx pbThrowPokeBall unless self.method_defined?(:pbThrowPokeBall_ebdx)
  def pbThrowPokeBall(idxPokemon, ball, rareness=nil, showplayer=false)
    # queues message for uncatchable Pokemon
    data = EliteBattle.get(:nextBattleData); data = {} if !data.is_a?(Hash)
    nocatch = data.has_key?(:CATCH_RATE) && data[:CATCH_RATE] < 0 && !@opponent
    @scene.briefmessage = true
    return pbThrowPokeBall_ebdx(idxPokemon, ball, rareness, showplayer) unless nocatch
    battler = nil
    battler = opposes?(idxPokemon) ? self.battlers[idxPokemon] : self.battlers[idxPokemon].pbOppositeOpposing
    battler = battler.pbPartner if battler.fainted?
    pbDisplayBrief(_INTL("{1} threw one {2}!", self.pbPlayer.name, PBItems.getName(ball)))
    if battler.fainted?
      pbDisplay(_INTL("But there was no target..."))
      return
    end
    @scene.pbThrow(ball, 0, false, battler.index, showplayer)
    pbDisplay(_INTL("This Pokémon doesn't appear to be catchable!"))
    BallHandlers.onFailCatch(ball, self, battler)
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  recalculate stats on capture (boss battlers fix)
module PokeBattle_BattleCommon
  alias pbStorePokemon_ebdx pbStorePokemon unless self.method_defined?(:pbStorePokemon_ebdx)
  def pbStorePokemon(pokemon)
    pokemon.calcStats
    return pbStorePokemon_ebdx(pokemon)
  end
end
#===============================================================================
