function hardcore_startup()
    local suggestions = {};
    local i = 1;
    
    for k, v in pairs(hardcore_emotes) do
        TwitchEmotes:AddEmote(k, k, v);
        suggestions[i] = k;
        i = i + 1;
    end
    
    -- Check if judhead_emotes exists before using it
    if judhead_emotes then
        for k, v in pairs(judhead_emotes) do
            TwitchEmotes:AddEmote(k, k, v);
            suggestions[i] = k;
            i = i + 1;
        end
    end
    
    hardcore_initsuggestions(suggestions);
end

function hardcore_concat(t1, t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function hardcore_initsuggestions(suggestions)
    if AllTwitchEmoteNames == nil
        or Emoticons_Settings == nil
        or Emoticons_RenderSuggestionFN == nil
        or not Emoticons_Settings["ENABLE_AUTOCOMPLETE"] then
        return;
    end

    -- Autocomplete is optional. Some clients may not expose this API.
    if type(SetupAutoComplete) ~= "function" then
        return;
    end

    hardcore_concat(suggestions, AllTwitchEmoteNames);
    table.sort(suggestions);

    local chatWindowCount = tonumber(NUM_CHAT_WINDOWS) or 0;
    for i = 1, chatWindowCount do
        local frame = _G["ChatFrame"..i];
        local editBox = frame and frame.editBox;

        -- A chat window may be unavailable or not fully initialized yet.
        if editBox then
            local maxButtonCount = 20;

            SetupAutoComplete(editBox, suggestions, maxButtonCount, {
                perWord = true,
                activationChar = ':',
                closingChar = ':',
                minChars = 2,
                fuzzyMatch = true,
                onSuggestionApplied = function(suggestion)
                    if UpdateEmoteStats ~= nil then
                        UpdateEmoteStats(suggestion, true, false, false);
                    end
                end,
                renderSuggestionFN = Emoticons_RenderSuggestionFN,
                suggestionBiasFN = function(suggestion, text)
                    --Bias the sorting function towards the most autocompleted emotes
                    if TwitchEmoteStatistics ~= nil and TwitchEmoteStatistics[suggestion] ~= nil then
                        return TwitchEmoteStatistics[suggestion][1] * 5
                    end
                    return 0;
                end,
                interceptOnEnterPressed = true,
                addSpace = true,
                useTabToConfirm = Emoticons_Settings["AUTOCOMPLETE_CONFIRM_WITH_TAB"],
                useArrowButtons = true,
            });
        end
    end
end

function hardcore_dump()
    local str = ""
    local i = 0
    
    for k, v in pairs(hardcore_emotes) do
        str = str .. "|Htel:name = " .. k .. "\npath = " .. v .. "|h|T" .. v .. "|t|h "
        i = i + 1
        if i == 8 then
            print(str)
            str = ""
            i = 0
        end
    end
    
    if i > 0 then
        print(str)
    end
    
    -- Check if judhead_emotes exists before using it
    if judhead_emotes then
        for k, v in pairs(judhead_emotes) do
            str = str .. "|Htel:name = " .. k .. "\npath = " .. v .. "|h|T" .. v .. "|t|h "
            i = i + 1
            if i == 8 then
                print(str)
                str = ""
                i = 0
            end
        end
        
        if i > 0 then
            print(str)
        end
    end
end

local function escpattern(x)
    return (x:gsub('%%', '%%%%')
             :gsub('^%^', '%%^')
             :gsub('%$$', '%%$')
             :gsub('%(', '%%(')
             :gsub('%)', '%%)')
             :gsub('%.', '%%.')
             :gsub('%[', '%%[')
             :gsub('%]', '%%]')
             :gsub('%*', '%%*')
             :gsub('%+', '%%+')
             :gsub('%-', '%%-')
             :gsub('%?', '%%?'))
end

function TwitchEmotesAnimator_UpdateEmoteInFontString(fontstring, widthOverride, heightOverride)
    if not fontstring then
        return;
    end

    -- Protect the read as well: client builds can differ in how chat text is exposed.
    local getTextOK, txt = pcall(fontstring.GetText, fontstring);
    if not getTextOK then
        return;
    end

    -- WoW may return secret/protected chat text during combat.
    -- Only skip that specific text; normal strings continue through animation.
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, txt);
        if ok and secret then
            return;
        end
    end

    if type(txt) ~= "string" or txt == "" then
        return;
    end

    if type(TwitchEmotes_animation_metadata) ~= "table"
        or type(TwitchEmotes_GetCurrentFrameNum) ~= "function"
        or type(TwitchEmotes_BuildEmoteFrameString) ~= "function" then
        return;
    end

    for emoteTextureString in txt:gmatch("(|TInterface\\AddOns\\TwitchEmotes.-|t)") do
        local imagepath = emoteTextureString:match("|T(Interface\\AddOns\\TwitchEmotes.-tga).-|t");
        local animdata = imagepath and TwitchEmotes_animation_metadata[imagepath];

        if type(animdata) == "table"
            and type(animdata.frameWidth) == "number"
            and type(animdata.frameHeight) == "number"
            and animdata.frameHeight > 0 then
            local framenum = TwitchEmotes_GetCurrentFrameNum(animdata);
            local nTxt;


            if type(TwitchEmotes_BuildEmoteFrameStringWithDimensions) == "function"
                and widthOverride ~= 16
                and animdata.frameWidth > 32
                and type(heightOverride) == "number"
                and heightOverride > 0 then

                local aspectRatio = animdata.frameWidth / animdata.frameHeight;
                local displayHeight = heightOverride;
                local displayWidth = math.floor(displayHeight * aspectRatio + 0.5);

                nTxt = txt:gsub(
                    escpattern(emoteTextureString),
                    TwitchEmotes_BuildEmoteFrameStringWithDimensions(
                        imagepath, animdata, framenum, displayHeight, displayWidth
                    )
                );
            elseif type(TwitchEmotes_BuildEmoteFrameStringWithDimensions) == "function"
                and type(widthOverride) == "number" and widthOverride > 0
                and type(heightOverride) == "number" and heightOverride > 0 then

                nTxt = txt:gsub(
                    escpattern(emoteTextureString),
                    TwitchEmotes_BuildEmoteFrameStringWithDimensions(
                        imagepath, animdata, framenum, widthOverride, heightOverride
                    )
                );
            else
                -- Keep the emote's native dimensions when no valid override
                -- was supplied, while still replacing its animation frame.
                nTxt = txt:gsub(
                    escpattern(emoteTextureString),
                    TwitchEmotes_BuildEmoteFrameString(imagepath, animdata, framenum)
                );
            end

            if fontstring.messageInfo ~= nil then
                fontstring.messageInfo.message = nTxt;
            end

            fontstring:SetText(nTxt);
            txt = nTxt;
        end
    end
end

hardcore_startup();
