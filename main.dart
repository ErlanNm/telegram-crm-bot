import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// 🔑 TOKEN (FIXED)
final token = Platform.environment['BOT_TOKEN'];
final url = 'https://api.telegram.org/bot$token';

// 👑 ADMIN
const adminChatId = 6161969307;

// ======================
// 🌍 LANGUAGE
// ======================
Map<int, String> lang = {};

// ======================
// 📦 STATE
// ======================
Map<int, String> step = {};
Map<int, Map<String, String>> data = {};
Map<int, Set<String>> doneSteps = {};

// ======================
// 🌍 TEXTS
// ======================
Map<String, Map<String, String>> t = {
  "ru": {
    "choose_lang": "🌍 Выберите язык:",
    "menu": "👋 Добро пожаловать!\nВыберите действие:",
    "sent": "✅ Заявка отправлена!",
    "course": "📚 Курс",
    "app": "📱 Заказ приложения",
    "name": "👤 Введите имя:",
    "phone": "📞 Введите телефон:",
    "budget": "💰 Укажите бюджет:",
    "type": "📱 Какое приложение нужно?",
    "desc": "📝 Кратко опишите проект:",
    "goal": "🎯 Зачем тебе курс?",
    "shop": "🛒 Магазин",
    "delivery": "🚚 Доставка",
    "taxi": "🚕 Такси",
    "education": "📚 Обучение",
    "other": "📱 Другое",
    "work": "💼 Работа",
    "freelance": "💸 Фриланс",
    "project": "🚀 Свой проект",
    "study": "📚 Просто учусь",
  },
  "kg": {
    "choose_lang": "🌍 Тилди тандаңыз:",
    "menu": "👋 Кош келиңиз!\nАракетти тандаңыз:",
    "sent": "✅ Өтүнмө жөнөтүлдү!",
    "course": "📚 Курс",
    "app": "📱 Приложение заказ",
    "name": "👤 Атыңызды жазыңыз:",
    "phone": "📞 Телефон жазыңыз:",
    "budget": "💰 Бюджетти жазыңыз:",
    "type": "📱 Кандай приложение керек?",
    "desc": "📝 Долбоорду кыскача сүрөттөңүз:",
    "goal": "🎯 Эмне үчүн курс керек?",
    "shop": "🛒 Дүкөн",
    "delivery": "🚚 Жеткирүү",
    "taxi": "🚕 Такси",
    "education": "📚 Окуу",
    "other": "📱 Башка",
    "work": "💼 Жумуш",
    "freelance": "💸 Фриланс",
    "project": "🚀 Өз долбоорум",
    "study": "📚 Жөн эле окуп жатам",
  }
};

// ======================
// 🔧 HELPER
// ======================
String tr(int chatId, String key) {
  final l = lang[chatId] ?? "ru";
  return t[l]?[key] ?? key;
}

// ======================
// 📤 SEND
// ======================
Future<void> sendMessage(int chatId, String text, [Map? keyboard]) async {
  try {
    final body = {'chat_id': chatId.toString(), 'text': text};

    if (keyboard != null) {
      body['reply_markup'] = jsonEncode(keyboard);
    }

    final res = await http.post(
      Uri.parse('$url/sendMessage'),
      body: body,
    );

    print("📤 RESPONSE: ${res.body}");
  } catch (e) {
    print("❌ sendMessage error: $e");
  }
}

// ======================
// ❌ REMOVE KEYBOARD
// ======================
Future<void> removeKeyboard(int chatId, String text) async {
  await http.post(
    Uri.parse('$url/sendMessage'),
    body: {
      'chat_id': chatId.toString(),
      'text': text,
      'reply_markup': jsonEncode({"remove_keyboard": true}),
    },
  );
}

// ======================
// 🚀 MAIN
// ======================
void main() async {
  if (token == null || token!.isEmpty) {
    print("❌ TOKEN IS NULL");
    return;
  }

  print("🚀 CRM BOT STARTED");
  print("TOKEN: $token");

  int offset = 0;

  while (true) {
    try {
      final res =
          await http.get(Uri.parse('$url/getUpdates?offset=$offset'));

      final json = jsonDecode(res.body);
      final result = json['result'] ?? [];

      for (var update in result) {
        offset = update['update_id'] + 1;

        final msg = update['message'];
        if (msg == null) continue;

        final chatId = msg['chat']['id'];
        final text = msg['text'] ?? '';

        print("📩 $chatId: $text");

        // init
        data.putIfAbsent(chatId, () => {});
        step.putIfAbsent(chatId, () => '');
        doneSteps.putIfAbsent(chatId, () => {});

        // START
        if (text == '/start') {
          await sendMessage(chatId, t["ru"]!["choose_lang"]!, {
            "keyboard": [
              [{"text": "🇷🇺 Русский"}],
              [{"text": "🇰🇬 Кыргызча"}],
            ],
            "resize_keyboard": true,
          });
        }

        // LANG
        else if (text == "🇷🇺 Русский") {
          lang[chatId] = "ru";

          await sendMessage(chatId, tr(chatId, "menu"), {
            "keyboard": [
              [{"text": tr(chatId, "course")}],
              [{"text": tr(chatId, "app")}],
            ],
            "resize_keyboard": true,
          });
        } else if (text == "🇰🇬 Кыргызча") {
          lang[chatId] = "kg";

          await sendMessage(chatId, tr(chatId, "menu"), {
            "keyboard": [
              [{"text": tr(chatId, "course")}],
              [{"text": tr(chatId, "app")}],
            ],
            "resize_keyboard": true,
          });
        }

        // APP START
        else if (text == tr(chatId, "app")) {
          step[chatId] = 'a_name';
          await sendMessage(chatId, tr(chatId, "name"));
        }

        // COURSE START
        else if (text == tr(chatId, "course")) {
          step[chatId] = 'c_name';
          await sendMessage(chatId, tr(chatId, "name"));
        }

        // FLOW
        else {
          final s = step[chatId];

          if (s == 'a_name') {
            data[chatId]!['name'] = text;
            step[chatId] = 'a_phone';
            await sendMessage(chatId, tr(chatId, "phone"));
          } else if (s == 'a_phone') {
            data[chatId]!['phone'] = text;
            step[chatId] = 'a_budget';
            await sendMessage(chatId, tr(chatId, "budget"));
          } else if (s == 'a_budget') {
            data[chatId]!['budget'] = text;
            step[chatId] = 'a_type';

            await sendMessage(chatId, tr(chatId, "type"), {
              "keyboard": [
                [{"text": tr(chatId, "shop")}],
                [{"text": tr(chatId, "delivery")}],
                [{"text": tr(chatId, "taxi")}],
                [{"text": tr(chatId, "education")}],
                [{"text": tr(chatId, "other")}],
              ],
              "resize_keyboard": true,
            });
          } else if (s == 'a_type') {
            data[chatId]!['type'] = text;
            step[chatId] = 'a_desc';

            await sendMessage(chatId, tr(chatId, "desc"), {
              "remove_keyboard": true,
            });
          } else if (s == 'a_desc') {
            data[chatId]!['desc'] = text;

            final lead = data[chatId]!;

            await sendMessage(
              adminChatId,
              "🔥 NEW APP LEAD\n\n"
              "👤 Name: ${lead['name']}\n"
              "📞 Phone: ${lead['phone']}\n"
              "💰 Budget: ${lead['budget']}\n"
              "📱 Type: ${lead['type']}\n"
              "📝 Desc: ${lead['desc']}\n"
              "👤 User: $chatId",
            );

            await removeKeyboard(chatId, tr(chatId, "sent"));

            await sendMessage(chatId, tr(chatId, "menu"), {
              "keyboard": [
                [{"text": tr(chatId, "course")}],
                [{"text": tr(chatId, "app")}],
              ],
              "resize_keyboard": true,
            });

            data[chatId] = {};
            step[chatId] = '';
          }

          // COURSE
          else if (s == 'c_name') {
            data[chatId]!['name'] = text;
            step[chatId] = 'c_phone';
            await sendMessage(chatId, tr(chatId, "phone"));
          } else if (s == 'c_phone') {
            data[chatId]!['phone'] = text;
            step[chatId] = 'c_goal';

            await sendMessage(chatId, tr(chatId, "goal"), {
              "keyboard": [
                [{"text": tr(chatId, "work")}],
                [{"text": tr(chatId, "freelance")}],
                [{"text": tr(chatId, "project")}],
                [{"text": tr(chatId, "study")}],
              ],
              "resize_keyboard": true,
            });
          } else if (s == 'c_goal') {
            data[chatId]!['goal'] = text;

            final lead = data[chatId]!;

            await sendMessage(
              adminChatId,
              "🔥 NEW COURSE LEAD\n\n"
              "👤 Name: ${lead['name']}\n"
              "📞 Phone: ${lead['phone']}\n"
              "🎯 Goal: ${lead['goal']}\n"
              "👤 User: $chatId",
            );

            await removeKeyboard(chatId, tr(chatId, "sent"));

            await sendMessage(chatId, tr(chatId, "menu"), {
              "keyboard": [
                [{"text": tr(chatId, "course")}],
                [{"text": tr(chatId, "app")}],
              ],
              "resize_keyboard": true,
            });

            data[chatId] = {};
            step[chatId] = '';
          }
        }
      }
    } catch (e) {
      print("❌ LOOP ERROR: $e");
    }

    await Future.delayed(Duration(seconds: 1));
  }
}
