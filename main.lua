function judhead_startup()
    local suggestions = {};
    local i = 1;

    for k, v in pairs(judhead_emotes) do
        TwitchEmotes:AddEmote(k, k, v);

        suggestions[i] = k;
        i = i + 1;
    end

    judhead_initsuggestions(suggestions);
end

function judhead_concat(t1, t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function judhead_initsuggestions(suggestions)
    if AllTwitchEmoteNames ~= nil and Emoticons_Settings ~= nil and Emoticons_RenderSuggestionFN ~= nil and Emoticons_Settings["ENABLE_AUTOCOMPLETE"] then

        judhead_concat(suggestions, AllTwitchEmoteNames);
        table.sort(suggestions);

        for i=1, NUM_CHAT_WINDOWS do
            local frame = _G["ChatFrame"..i]

            local maxButtonCount = 20;

            SetupAutoComplete(frame.editBox, suggestions, maxButtonCount, {
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

function judhead_dump()
    local str = ""
    local i = 0

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
    local txt = fontstring:GetText();
    if (txt ~= nil) then
        for emoteTextureString in txt:gmatch("(|TInterface\\AddOns\\TwitchEmotes.-|t)") do
            local imagepath = emoteTextureString:match("|T(Interface\\AddOns\\TwitchEmotes.-tga).-|t")

            local animdata = TwitchEmotes_animation_metadata[imagepath];
            -- print(animdata)
            if (animdata ~= nil) then
                local framenum = TwitchEmotes_GetCurrentFrameNum(animdata);
                local nTxt;
                if(widthOverride ~= nil or heightOverride ~= nil) then
                    nTxt = txt:gsub(escpattern(emoteTextureString),
                                        TwitchEmotes_BuildEmoteFrameStringWithDimensions(
                                        imagepath, animdata, framenum, widthOverride, heightOverride))
                else
                    nTxt = txt:gsub(escpattern(emoteTextureString),
                                      TwitchEmotes_BuildEmoteFrameString(
                                        imagepath, animdata, framenum))
                end

                -- If we're updating a chat message we need to alter the messageInfo as wel
                if (fontstring.messageInfo ~= nil) then
                    fontstring.messageInfo.message = nTxt
                end
                fontstring:SetText(nTxt);
                txt = nTxt;
            end
        end
    end
end

judhead_startup();
