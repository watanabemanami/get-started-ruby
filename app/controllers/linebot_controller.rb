class LinebotController < ApplicationController
    require "line/bot"  # gem "line-bot-api"

    # callbackアクションのCSRFトークン認証を無効
    protect_from_forgery :except => [:callback]
    GOMI = {"生ごみ" => "燃えるゴミ","たんす" => "粗大ごみ","トレイ" => "プラスチック","スプレー" => "金属"}

    def client
      @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end
    
    def callback
      body = request.body.read
  
      signature = request.env["HTTP_X_LINE_SIGNATURE"]
      unless client.validate_signature(body, signature)
        error 400 do "Bad Request" en
      end
  
      events = client.parse_events_from(body)
  
      events.each { |event|
        case event
        when Line::Bot::Event::Message
          case event.type
          when Line::Bot::Event::MessageType::Text
            key = event.message["text"]
            message = {
              type: "text",
              text: GOMI[key]
            }
            client.reply_message(event["replyToken"], message)
            
          when Line::Bot::Event::MessageType::Location
            message = {
              type: "location",
              title: "あなたはここにいますか？",
              address: event.message["address"],
              latitude: event.message["latitude"],
              longitude: event.message["longitude"]
            }
            client.reply_message(event["replyToken"], message)
          end
        end
      }
  
      head :ok
    end
end