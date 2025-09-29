submitButton.MouseButton1Click:Connect(function()
    local devApiKey = "8c0195cb4634d6a4eab953590b1683f5035d961f28e7089230d36d8989c6db7c"
    local verificationUrl = "https://api.lootlabs.io/v1/key/verify"
    local userKey = keyInput.Text

    if userKey == "" then return end

    local requestBody = httpService:JSONEncode({
        key = userKey
    })

    local headers = {
        ["api-key"] = devApiKey,
        ["Content-Type"] = "application/json"
    }

    submitButton.Text = "Verifying..."

    local success, result = pcall(function()
        return httpService:PostAsync(verificationUrl, requestBody, Enum.HttpContentType.ApplicationJson, false, headers)
    end)

    if success then
        local response = httpService:JSONDecode(result)
        if response and response.success == true then
            keyFrame.Visible = false
            mainFrame.Visible = true
        else
            local reason = response and response.message or "Incorrect Key"
            submitButton.Text = reason
            task.wait(2)
            submitButton.Text = "Submit"
        end
    else
        submitButton.Text = "API Error"
        task.wait(2)
        submitButton.Text = "Submit"
    end
end)
