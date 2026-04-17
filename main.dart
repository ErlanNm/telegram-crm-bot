import 'dart:convert';
import 'package:http/http.dart' as http;

// 🔑 TOKEN

const token = String.fromEnvironment('BOT_TOKEN');
const url = 'https://api.telegram.org/bot$token';

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
// 🌍 TEXTS (RU + KG)
// ======================
Map<String, Map<String, String>> t = {
  "ru": {
    // system
    "choose_lang": "🌍 Выберите язык:",
    "menu": "👋 Добро пожаловать!\nВыберите действие:",
    "sent": "✅ Заявка отправлена!",

    // buttons
    "course": "📚 Курс",
    "app": "📱 Заказ приложения",

    // fields
    "name": "👤 Введите имя:",
    "phone": "📞 Введите телефон:",
    "budget": "💰 Укажите бюджет:",
    "type": "📱 Какое приложение нужно?",
    "desc": "📝 Кратко опишите проект:",
    "goal": "🎯 Зачем тебе курс?",

    // app types
    "shop": "🛒 Магазин",
    "delivery": "🚚 Доставка",
    "taxi": "🚕 Такси",
    "education": "📚 Обучение",
    "other": "📱 Другое",

    // course goals
    "work": "💼 Работа",
    "freelance": "💸 Фриланс",
    "project": "🚀 Свой проект",
    "study": "📚 Просто учусь",
  },

  "kg": {
    // system
    "choose_lang": "🌍 Тилди тандаңыз:",
    "menu": "👋 Кош келиңиз!\nАракетти тандаңыз:",
    "sent": "✅ Өтүнмө жөнөтүлдү!",

    // buttons
    "course": "📚 Курс",
    "app": "📱 Приложение заказ",

    // fields
    "name": "👤 Атыңызды жазыңыз:",
    "phone": "📞 Телефон жазыңыз:",
    "budget": "💰 Бюджетти жазыңыз:",
    "type": "📱 Кандай приложение керек?",
    "desc": "📝 Долбоорду кыскача сүрөттөңүз:",
    "goal": "🎯 Эмне үчүн курс керек?",

    // app types
    "shop": "🛒 Дүкөн",
    "delivery": "🚚 Жеткирүү",
    "taxi": "🚕 Такси",
    "education": "📚 Окуу",
    "other": "📱 Башка",

    // course goals
    "work": "💼 Жумуш",
    "freelance": "💸 Фриланс",
    "project": "🚀 Өз долбоорум",
    "study": "📚 Жөн эле окуп жатам",
  }
};

// ======================
// 🔧 HELPERS
// ======================
String tr(int chatId, String key) {
  final l = lang[chatId] ?? "ru";
  return t[l]?[key] ?? key;
}

// ======================
// 📤 SEND MESSAGE
// ======================
Future<Map<String, dynamic>> sendMessage(
  int chatId,
  String text, [
  Map? keyboard,
]) async {
  final body = {'chat_id': chatId.toString(), 'text': text};

  if (keyboard != null) {
    body['reply_markup'] = jsonEncode(keyboard);
  }

  final res = await http.post(Uri.parse('$url/sendMessage'), body: body);
  return jsonDecode(res.body);
}

// ======================
// 💣 REMOVE KEYBOARD
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
  int offset = 0;

  print("🚀 CRM BOT STARTED");

  while (true) {
    final res = await http.get(Uri.parse('$url/getUpdates?offset=$offset'));
    final json = jsonDecode(res.body);

    for (var update in json['result']) {
      offset = update['update_id'] + 1;

      final msg = update['message'];
      if (msg == null) continue;

      final chatId = msg['chat']['id'];
      final text = msg['text'] ?? '';

      // init
      data.putIfAbsent(chatId, () => {});
      step.putIfAbsent(chatId, () => '');
      doneSteps.putIfAbsent(chatId, () => {});

      // ======================
      // /START (LANG)
      // ======================
      if (text == '/start') {
        step[chatId] = '';

        await sendMessage(chatId, t["ru"]!["choose_lang"]!, {
          "keyboard": [
            [{"text": "🇷🇺 Русский"}],
            [{"text": "🇰🇬 Кыргызча"}],
          ],
          "resize_keyboard": true,
        });
      }

      // ======================
      // LANGUAGE SET
      // ======================
      else if (text == "🇷🇺 Русский") {
        lang[chatId] = "ru";
        step[chatId] = '';

        await sendMessage(chatId, tr(chatId, "menu"), {
          "keyboard": [
            [{"text": tr(chatId, "course")}],
            [{"text": tr(chatId, "app")}],
          ],
          "resize_keyboard": true,
        });
      }

      else if (text == "🇰🇬 Кыргызча") {
        lang[chatId] = "kg";
        step[chatId] = '';

        await sendMessage(chatId, tr(chatId, "menu"), {
          "keyboard": [
            [{"text": tr(chatId, "course")}],
            [{"text": tr(chatId, "app")}],
          ],
          "resize_keyboard": true,
        });
      }

      // ======================
      // APP START
      // ======================
      else if (text == tr(chatId, "app")) {
        step[chatId] = 'a_name';
        await sendMessage(chatId, tr(chatId, "name"));
      }

      // ======================
      // COURSE START
      // ======================
      else if (text == tr(chatId, "course")) {
        step[chatId] = 'c_name';
        await sendMessage(chatId, tr(chatId, "name"));
      }

      // ======================
      // FLOW
      // ======================
      else {
        final s = step[chatId];

        // 📱 APP FLOW
        if (s == 'a_name') {
          data[chatId]!['name'] = text;
          step[chatId] = 'a_phone';
          await sendMessage(chatId, tr(chatId, "phone"));
        }

        else if (s == 'a_phone') {
          data[chatId]!['phone'] = text;
          step[chatId] = 'a_budget';
          await sendMessage(chatId, tr(chatId, "budget"));
        }

        else if (s == 'a_budget') {
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
        }

        else if (s == 'a_type') {
          data[chatId]!['type'] = text;
          step[chatId] = 'a_desc';

          await sendMessage(chatId, tr(chatId, "desc"), {
            "remove_keyboard": true,
          });
        }

        else if (s == 'a_desc') {
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
          doneSteps[chatId] = {};
        }

        // 📚 COURSE FLOW
        else if (s == 'c_name') {
          data[chatId]!['name'] = text;
          step[chatId] = 'c_phone';
          await sendMessage(chatId, tr(chatId, "phone"));
        }

        else if (s == 'c_phone') {
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
        }

        else if (s == 'c_goal') {
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
          doneSteps[chatId] = {};
        }
      }
    }

    await Future.delayed(Duration(seconds: 1));
  }
}


