import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ======================
// 🔑 TOKEN
// ======================
final String? token = Platform.environment['BOT_TOKEN'];
late final String url;

// 👑 ADMIN
const int adminChatId = 6161969307;

// ======================
// 🌍 STATE
// ======================
Map<int, String> lang = {};
Map<int, String> step = {};
Map<int, Map<String, String>> data = {};

// ======================
// 🌍 TEXTS
// ======================
Map<String, Map<String, String>> t = {
  "ru": {
    "choose_lang": "🌍 Выберите язык:",
    "menu": "👋 Меню:",
    "sent": "✅ Заявка отправлена!",

    "course": "📚 Курс",
    "app": "📱 Приложение",
    "bot": "🤖 Заказать бота",

    "name": "👤 Имя:",
    "phone": "📞 Телефон:",
    "budget": "💰 Бюджет:",
    "type": "📱 Тип:",
    "desc": "📝 Описание:",

    "bot_type": "🤖 Какой бот нужен?",
    "goal": "🎯 Цель:",
  },
  "kg": {
    "choose_lang": "🌍 Тилди тандаңыз:",
    "menu": "👋 Меню:",
    "sent": "✅ Жөнөтүлдү!",

    "course": "📚 Курс",
    "app": "📱 Приложение",
    "bot": "🤖 Бот заказ",

    "name": "👤 Атыңыз:",
    "phone": "📞 Телефон:",
    "budget": "💰 Бюджет:",
    "type": "📱 Түрү:",
    "desc": "📝 Сүрөттөмө:",

    "bot_type": "🤖 Кандай бот керек?",
    "goal": "🎯 Максат:",
  }
};

// ======================
// 🔧 HELPER
// ======================
String tr(int chatId, String key) {
  final l = lang[chatId] ?? "ru";
  return t[l]?[key] ?? t["ru"]![key] ?? key;
}

// ======================
// 📤 SEND MESSAGE
// ======================
Future<void> sendMessage(int chatId, String text, [Map? keyboard]) async {
  final body = {
    "chat_id": chatId.toString(),
    "text": text,
  };

  if (keyboard != null) {
    body["reply_markup"] = jsonEncode(keyboard);
  }

  await http.post(Uri.parse("$url/sendMessage"), body: body);
}

// ======================
// 🚀 MAIN
// ======================
void main() async {
  if (token == null || token!.isEmpty) {
    print("❌ BOT_TOKEN missing");
    return;
  }

  url = "https://api.telegram.org/bot$token";

  print("🚀 BOT STARTED");

  int offset = 0;

  while (true) {
    try {
      final res = await http.get(Uri.parse("$url/getUpdates?offset=$offset"));
      final json = jsonDecode(res.body);

      final result = json["result"] ?? [];

      for (var update in result) {
        offset = update["update_id"] + 1;

        final msg = update["message"];
        if (msg == null) continue;

        final int chatId = msg["chat"]["id"];
        final String text = msg["text"] ?? "";

        data.putIfAbsent(chatId, () => {});
        step.putIfAbsent(chatId, () => "");

        print("📩 $chatId: $text");

        // ======================
        // START
        // ======================
        if (text == "/start") {
          await sendMessage(chatId, t["ru"]!["choose_lang"]!, {
            "keyboard": [
              [{"text": "🇷🇺 Русский"}],
              [{"text": "🇰🇬 Кыргызча"}],
            ],
            "resize_keyboard": true,
          });
        }

        // ======================
        // LANGUAGE + MENU
        // ======================
        else if (text == "🇷🇺 Русский") {
          lang[chatId] = "ru";

          await sendMessage(chatId, tr(chatId, "menu"), {
            "keyboard": [
              [{"text": tr(chatId, "app")}],
              [{"text": tr(chatId, "course")}],
              [{"text": tr(chatId, "bot")}], // ✅ FIXED
            ],
            "resize_keyboard": true,
          });
        }

        else if (text == "🇰🇬 Кыргызча") {
          lang[chatId] = "kg";

          await sendMessage(chatId, tr(chatId, "menu"), {
            "keyboard": [
              [{"text": tr(chatId, "app")}],
              [{"text": tr(chatId, "course")}],
              [{"text": tr(chatId, "bot")}], // ✅ FIXED
            ],
            "resize_keyboard": true,
          });
        }

        // ======================
        // START FLOWS
        // ======================
        else if (text == tr(chatId, "app")) {
          step[chatId] = "a_name";
          await sendMessage(chatId, tr(chatId, "name"));
        }

        else if (text == tr(chatId, "course")) {
          step[chatId] = "c_name";
          await sendMessage(chatId, tr(chatId, "name"));
        }

        else if (text == tr(chatId, "bot")) {
          step[chatId] = "b_name";
          await sendMessage(chatId, tr(chatId, "name"));
        }

        // ======================
        // FLOW ENGINE
        // ======================
        else {
          final s = step[chatId] ?? "";

          // ===== APP =====
          if (s == "a_name") {
            data[chatId]!["name"] = text;
            step[chatId] = "a_phone";
            await sendMessage(chatId, tr(chatId, "phone"));
          }

          else if (s == "a_phone") {
            data[chatId]!["phone"] = text;
            step[chatId] = "a_budget";
            await sendMessage(chatId, tr(chatId, "budget"));
          }

          else if (s == "a_budget") {
            data[chatId]!["budget"] = text;
            step[chatId] = "a_type";

            await sendMessage(chatId, tr(chatId, "type"), {
              "keyboard": [
                [{"text": "🛒 Shop"}],
                [{"text": "🚕 Taxi"}],
                [{"text": "🚚 Delivery"}],
                [{"text": "📚 Education"}],
              ],
              "resize_keyboard": true,
            });
          }

          else if (s == "a_type") {
            data[chatId]!["type"] = text;
            step[chatId] = "a_desc";
            await sendMessage(chatId, tr(chatId, "desc"), {"remove_keyboard": true});
          }

          else if (s == "a_desc") {
            await sendMessage(adminChatId, "🔥 APP LEAD\n$text");
            data.remove(chatId);
            step.remove(chatId);
          }

          // ===== BOT =====
          else if (s == "b_name") {
            data[chatId]!["name"] = text;
            step[chatId] = "b_phone";
            await sendMessage(chatId, tr(chatId, "phone"));
          }

          else if (s == "b_phone") {
            data[chatId]!["phone"] = text;
            step[chatId] = "b_type";

            await sendMessage(chatId, tr(chatId, "bot_type"), {
              "keyboard": [
                [{"text": "🛒 Shop Bot"}],
                [{"text": "💬 CRM Bot"}],
                [{"text": "🤖 AI Bot"}],
              ],
              "resize_keyboard": true,
            });
          }

          else if (s == "b_type") {
            data[chatId]!["type"] = text;
            step[chatId] = "b_desc";
            await sendMessage(chatId, tr(chatId, "desc"), {"remove_keyboard": true});
          }

          else if (s == "b_desc") {
            await sendMessage(adminChatId, "🔥 BOT LEAD\n$text");
            data.remove(chatId);
            step.remove(chatId);
          }

          // ===== COURSE =====
          else if (s == "c_name") {
            data[chatId]!["name"] = text;
            step[chatId] = "c_phone";
            await sendMessage(chatId, tr(chatId, "phone"));
          }

          else if (s == "c_phone") {
            data[chatId]!["phone"] = text;
            step[chatId] = "c_goal";
            await sendMessage(chatId, tr(chatId, "goal"));
          }

          else if (s == "c_goal") {
            await sendMessage(adminChatId, "🔥 COURSE LEAD\n$text");
            data.remove(chatId);
            step.remove(chatId);
          }
        }
      }
    } catch (e) {
      print("❌ ERROR: $e");
    }

    await Future.delayed(Duration(seconds: 1));
  }
}
