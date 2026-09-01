import NaturalLanguage

let samples: [(String, String)] = [
    (
        "en2",
        "I really enjoyed reading your article, especially the part about public transportation."
    ),
    (
        "fr2",
        "Le gouvernement annonce une nouvelle mesure pour améliorer les transports publics."
    ),
    (
        "es2",
        "Mañana iremos al mercado para comprar frutas frescas y preparar la cena."
    ),
    (
        "de2",
        "Am Wochenende fahren wir mit dem Zug in die Berge und besuchen unsere Freunde."
    ),
    (
        "it2",
        "Domani andremo al mercato per comprare frutta fresca e preparare la cena."
    ),
    (
        "pt2",
        "Amanhã vamos ao mercado comprar frutas frescas e preparar o jantar."
    ),
    (
        "nl2",
        "Morgen gaan we met de trein naar de stad om onze vrienden te bezoeken."
    ),
    (
        "ca2",
        "Demà anirem al mercat per comprar fruita fresca i preparar el sopar."
    ),
    (
        "sv2",
        "I morgon tar vi tåget till staden för att träffa våra vänner."
    ),
    (
        "da2",
        "I morgen tager vi toget til byen for at besøge vores venner."
    ),
    (
        "nb2",
        "I morgen tar vi toget til byen for å besøke vennene våre."
    ),
    ("fi2", "Huomenna menemme junalla kaupunkiin tapaamaan ystäviämme."),
    (
        "pl2",
        "Jutro pojedziemy pociągiem do miasta, aby odwiedzić naszych przyjaciół."
    ),
    ("cs2", "Zítra pojedeme vlakem do města navštívit naše přátele."),
    ("hr2", "Sutra ćemo vlakom otići u grad posjetiti naše prijatelje."),
    (
        "ro2",
        "Mâine vom merge cu trenul în oraș pentru a ne vizita prietenii."
    ),
    (
        "tr2",
        "Yarın arkadaşlarımızı ziyaret etmek için trenle şehre gideceğiz."
    ),
    (
        "id2",
        "Besok kami naik kereta ke kota untuk mengunjungi teman-teman kami."
    ),
    ("vi2", "Ngày mai chúng tôi sẽ đi tàu vào thành phố để thăm bạn bè."),
    ("ja2", "明日は電車で町へ行って友達に会います。"),
    ("ko2", "내일 우리는 친구들을 만나기 위해 기차를 타고 도시로 갑니다."),
    ("zh2", "明天我们坐火车去城里看望朋友。"),
    ("ru2", "Завтра мы поедем на поезде в город, чтобы навестить друзей."),
    ("uk2", "Завтра ми поїдемо потягом до міста, щоб відвідати друзів."),
    ("el2", "Αύριο θα πάμε με το τρένο στην πόλη για να επισκεφτούμε φίλους."),
    ("ar2", "غدًا سنذهب بالقطار إلى المدينة لزيارة أصدقائنا."),
    ("he2", "מחר ניסע ברכבת לעיר כדי לבקר את החברים שלנו."),
    ("hi2", "कल हम अपने दोस्तों से मिलने ट्रेन से शहर जाएंगे।"),
    ("th2", "พรุ่งนี้เราจะนั่งรถไฟเข้าเมืองเพื่อไปเยี่ยมเพื่อน"),
]

for (label, text) in samples {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    let top = recognizer.languageHypotheses(withMaximum: 1).first
    let confidence = (top?.value ?? 0) >= 0.85 ? "high" : "low"
    print("\(label)=\(top?.key.rawValue ?? "nil"),\(confidence)")
}
