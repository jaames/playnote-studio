CreditsScreen = {}
class('CreditsScreen').extends(ScreenBase)

function CreditsScreen:init()
  CreditsScreen.super.init(self)
  self.scroll = ScrollController(self)
  self.scroll:setStart(200)
  self.scroll:useDpad()
end

function CreditsScreen:getArtistCredits()
  local text = ''
  local credits = noteFs:getArtistCredits()
  for _, artist in pairs(credits) do
    text = text .. stringUtils:escape(artist.name) .. '\n'
    for _, link in pairs(artist.links) do
      text = text .. '_' .. stringUtils:escape(link) .. '_\n'
    end
    text = text .. '\n'
  end
  return text
end

function CreditsScreen:getCreditsText()
  local text = fsUtils:readText('./data/credits.txt')
  local artistCredits = self:getArtistCredits()
  -- replace placeholders in credits text
  text = locales:replaceKeysInText(text)
  text = stringUtils:replaceVars(text, {
    version = playdate.metadata.version,
    artistCredits = artistCredits
  })
  return text
end

function CreditsScreen:setupSprites()
  local logo = Image(PLAYDATE_W / 2, 0, './gfx/gfx_logo_credits')
  logo:setAnchor('center', 'top')

  local textView = TextView(0, logo.height + 12, PLAYDATE_W)
  textView:setText(self:getCreditsText())

  self.scroll:setHeight(logo.height + 12 + textView.height)

  return { logo, textView }
end

function CreditsScreen:beforeEnter()
  CreditsScreen.super.beforeEnter(self)
  self.scroll.autoScroll = false
  self.scroll:resetOffset()
end

function CreditsScreen:afterEnter()
  CreditsScreen.super.afterEnter(self)
  -- begin scrolling after enter transition
  self.scroll.autoScroll = true
end

function CreditsScreen:drawBg()
  gfx.setColor(gfx.kColorBlack)
  gfx.fillRect(0, 0, PLAYDATE_W, PLAYDATE_H)
end

function CreditsScreen:update()
  -- auto scroll
  self.scroll:update()
end