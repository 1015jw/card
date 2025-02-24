import 'package:flutter/material.dart';

void main() {
  runApp(SpiderSolitaireApp());
}

class Card {
  final String value;
  bool isFaceUp;

  Card(this.value, {this.isFaceUp = false});
}

class SpiderSolitaireApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spider Solitaire',
      theme: ThemeData.dark(),
      home: SpiderSolitaireScreen(),
    );
  }
}

class SpiderSolitaireScreen extends StatefulWidget {
  @override
  _SpiderSolitaireScreenState createState() => _SpiderSolitaireScreenState();
}

class _SpiderSolitaireScreenState extends State<SpiderSolitaireScreen> {
  List<List<Card>> columns = List.generate(5, (_) => []); // 5개의 카드뭉치
  List<Card> hiddenCards = []; // 숨겨진 카드 리스트
  List<Card?> tempSlots = List.generate(3, (_) => null); // 3개의 임시 저장소
  bool isShuffled = false; // 카드가 섞였는지 여부
  int specialItemCount = 5; // 아이템 사용 횟수
  bool isSpecialItemActive = false; // 아이템 활성화 상태
  int score = 0; // 점수

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    List<Card> deck = _createSpiderDeck();

    // 5개 카드뭉치에 13장씩 배치
    for (int i = 0; i < 5; i++) {
      columns[i] = deck.sublist(i * 13, (i + 1) * 13);
    }

    setState(() {});
  }

  List<Card> _createSpiderDeck() {
    List<Card> deck = [];
    for (int i = 1; i <= 13; i++) {
      String cardValue;
      switch (i) {
        case 1:
          cardValue = 'A';
          break;
        case 11:
          cardValue = 'J';
          break;
        case 12:
          cardValue = 'Q';
          break;
        case 13:
          cardValue = 'K';
          break;
        default:
          cardValue = i.toString();
      }
      deck.addAll(List.generate(5, (_) => Card('♠$cardValue')));
    }
    return deck;
  }

  void _shuffleCards() {
    if (isShuffled) return;

    List<Card> allCards = columns.expand((col) => col).toList();
    allCards.shuffle();

    hiddenCards = allCards.sublist(65 - 30);

    int remainingCards = 65 - 30;
    for (int i = 0; i < 5; i++) {
      int start = i * (remainingCards ~/ 5);
      int end = (i == 4) ? remainingCards : start + (remainingCards ~/ 5);
      columns[i] = allCards.sublist(start, end);

      // 초기 카드 상태 설정: 마지막 3장은 앞면, 나머지는 뒷면
      for (int j = 0; j < columns[i].length; j++) {
        columns[i][j].isFaceUp = j >= columns[i].length - 3;
      }
    }

    setState(() {
      isShuffled = true;
    });
  }

  bool _canAcceptCard(Card topCard, Card newCard) {
    const cardOrder = [
      'K',
      'Q',
      'J',
      '10',
      '9',
      '8',
      '7',
      '6',
      '5',
      '4',
      '3',
      '2',
      'A'
    ];
    int topIndex = cardOrder.indexOf(topCard.value.substring(1));
    int newIndex = cardOrder.indexOf(newCard.value.substring(1));
    return newIndex == topIndex + 1;
  }

  bool _isOrdered(List<Card> cards) {
    if (!cards.every((card) => card.isFaceUp)) return false;

    const cardOrder = [
      'K',
      'Q',
      'J',
      '10',
      '9',
      '8',
      '7',
      '6',
      '5',
      '4',
      '3',
      '2',
      'A'
    ];
    for (int i = 0; i < cards.length - 1; i++) {
      int currentIndex = cardOrder.indexOf(cards[i].value.substring(1));
      int nextIndex = cardOrder.indexOf(cards[i + 1].value.substring(1));
      if (nextIndex != currentIndex + 1) {
        return false;
      }
    }
    return true;
  }

  void _checkAndFlipCards() {
    for (var column in columns) {
      if (column.isEmpty) continue;
      bool hasFaceUpCard = column.any((card) => card.isFaceUp);
      if (!hasFaceUpCard) {
        column.last.isFaceUp = true;
      }
    }
  }

  void _checkAndRemoveCompletedSets() {
    for (var column in columns) {
      if (column.length >= 13) {
        List<Card> last13Cards = column.sublist(column.length - 13);
        if (_isOrdered(last13Cards)) {
          setState(() {
            column.removeRange(column.length - 13, column.length);
            score++;
          });
        }
      }
    }
  }

  Widget _buildTempSlots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) => _buildTempSlot(index)),
    );
  }

  Widget _buildTempSlot(int index) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5),
      child: DragTarget<Map<String, dynamic>>(
        onWillAccept: (data) {
          return tempSlots[index] == null;
        },
        onAccept: (data) {
          setState(() {
            tempSlots[index] = data['card'];
            columns[data['fromColumn']].removeAt(data['cardIndex']);
            _checkAndFlipCards();
            _checkAndRemoveCompletedSets();
          });
        },
        builder: (context, candidateData, rejectedData) {
          return tempSlots[index] == null
              ? _emptySlot()
              : Draggable<Map<String, dynamic>>(
                  data: {
                    'card': tempSlots[index],
                    'fromTempSlot': true,
                    'slotIndex': index,
                  },
                  feedback: Material(
                    child:
                        _cardWidget(tempSlots[index]!.value, isDragging: true),
                  ),
                  childWhenDragging: _emptySlot(),
                  child: _cardWidget(tempSlots[index]!.value),
                );
        },
      ),
    );
  }

  Widget _emptySlot() {
    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spider Solitaire')),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => _buildColumn(index)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHiddenCards(),
                    SizedBox(width: 20),
                    _buildTempSlots(),
                  ],
                ),
              ],
            ),
          ),
          if (!isShuffled)
            Padding(
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: _shuffleCards,
                child: Text("게임 시작"),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: specialItemCount > 0 ? _toggleSpecialItem : null,
              child: Text("중간 카드 빼오기 (${specialItemCount})"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSpecialItemActive ? Colors.red : null,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Text('점수: $score', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  void _toggleSpecialItem() {
    setState(() {
      isSpecialItemActive = !isSpecialItemActive;
    });
  }

  Widget _buildColumn(int index) {
    return Container(
      width: 60,
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: DragTarget<Map<String, dynamic>>(
        onWillAccept: (data) {
          if (data!['fromTempSlot'] == true) {
            if (columns[index].isEmpty) return true;
            return _canAcceptCard(columns[index].last, data['card']);
          }
          if (columns[index].isEmpty) return true;
          Card topCard = columns[index].last;
          return _canAcceptCard(topCard, data['card']);
        },
        onAccept: (data) {
          setState(() {
            if (data['fromTempSlot'] == true) {
              columns[index].add(data['card']);
              tempSlots[data['slotIndex']] = null;
            } else {
              List<Card> movingCards;
              if (isSpecialItemActive) {
                movingCards = [data['card']];
                columns[data['fromColumn']].removeAt(data['cardIndex']);
                specialItemCount--;
                isSpecialItemActive = false;
              } else {
                movingCards =
                    columns[data['fromColumn']].sublist(data['cardIndex']);
                columns[data['fromColumn']].removeRange(
                    data['cardIndex'], columns[data['fromColumn']].length);
              }
              columns[index].addAll(movingCards);
            }
            _checkAndFlipCards();
            _checkAndRemoveCompletedSets();
          });
        },
        builder: (context, candidateData, rejectedData) {
          return SizedBox(
            height: 400,
            child: Stack(
              children: columns[index]
                  .asMap()
                  .entries
                  .map((entry) => _buildCard(entry.value, index, entry.key))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHiddenCards() {
    return GestureDetector(
      onTap: _dealHiddenCards,
      child: Container(
        width: 60,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Text(
            '${hiddenCards.length}',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _dealHiddenCards() {
    if (hiddenCards.length < 5) return;

    setState(() {
      for (int i = 0; i < 5; i++) {
        var card = hiddenCards.removeLast();
        card.isFaceUp = true;
        columns[i].add(card);
      }
    });
  }

  Widget _buildCard(Card card, int columnIndex, int cardIndex) {
    bool isOrdered =
        card.isFaceUp && _isOrdered(columns[columnIndex].sublist(cardIndex));
    return Positioned(
      top: cardIndex * 25.0,
      child: isOrdered || (isSpecialItemActive && card.isFaceUp)
          ? Draggable<Map<String, dynamic>>(
              data: {
                'card': card,
                'fromColumn': columnIndex,
                'cardIndex': cardIndex,
              },
              childWhenDragging: _buildDragPlaceholder(columnIndex, cardIndex),
              feedback: Material(
                child: _buildDragFeedback(columnIndex, cardIndex),
              ),
              child: _cardWidget(card.value, isFaceUp: card.isFaceUp),
            )
          : _cardWidget(card.value, isFaceUp: card.isFaceUp),
    );
  }

  Widget _buildDragPlaceholder(int columnIndex, int cardIndex) {
    if (isSpecialItemActive) {
      return Container(
        width: 50,
        height: 70,
        margin: EdgeInsets.only(top: cardIndex * 25.0),
      );
    }

    List<Card> cardsToDrag = columns[columnIndex].sublist(cardIndex);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: cardsToDrag
          .asMap()
          .entries
          .map((entry) => Container(
                width: 50,
                height: 70,
                margin: EdgeInsets.only(top: entry.key * 25.0),
              ))
          .toList(),
    );
  }

  Widget _buildDragFeedback(int columnIndex, int cardIndex) {
    if (isSpecialItemActive) {
      return Material(
        child: _cardWidget(
          columns[columnIndex][cardIndex].value,
          isDragging: true,
          isFaceUp: columns[columnIndex][cardIndex].isFaceUp,
        ),
      );
    }

    List<Card> cardsToDrag = columns[columnIndex].sublist(cardIndex);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: cardsToDrag
          .asMap()
          .entries
          .map((entry) => _cardWidget(entry.value.value,
              isDragging: true, isFaceUp: entry.value.isFaceUp))
          .toList(),
    );
  }

  Widget _cardWidget(String value,
      {bool isDragging = false, bool isFaceUp = true}) {
    return Container(
      width: 50,
      height: 70,
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : Colors.grey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
        boxShadow:
            isDragging ? [BoxShadow(color: Colors.black26, blurRadius: 4)] : [],
      ),
      child: Stack(
        children: [
          if (isFaceUp)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 아이템 사용하고 드래그했을 때 클릭한 카드 기준으로 아래의 카드까지 전부 드래그되는 것처럼 보이는 문제 수정 필요
