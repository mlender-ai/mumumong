import '../../domain/model/models.dart';

class MockPassageTemplate {
  const MockPassageTemplate.dream(this.text, this.elementIndex)
    : origin = PassageOrigin.dream,
      cReason = null;

  const MockPassageTemplate.connection(this.text, this.cReason)
    : origin = PassageOrigin.connection,
      elementIndex = null;

  final String text;
  final PassageOrigin origin;
  final int? elementIndex;
  final String? cReason;
}

class MockSceneTemplate {
  const MockSceneTemplate({
    required this.title,
    required this.openImage,
    required this.elementLabels,
    required this.passages,
  });

  final String title;
  final String openImage;
  final List<String> elementLabels;
  final List<MockPassageTemplate> passages;
}

const regularMockScene = MockSceneTemplate(
  title: '문 밖의 여자',
  openImage: '문틈으로 물소리가 새어 나오고 있었다.',
  elementLabels: ['물이 찬 복도', '붉은 문', '우산을 든 여자', '문틈의 물소리'],
  passages: [
    MockPassageTemplate.dream(
      '복도 바닥에 물이 차 있었다. 걸음을 옮길 때마다 얇은 파문이 벽까지 밀려갔다.',
      0,
    ),
    MockPassageTemplate.dream('복도 끝에는 붉은 문 하나가 닫힌 채 서 있었다.', 1),
    MockPassageTemplate.dream('문 옆의 여자는 우산을 펴지 않고 손잡이만 가만히 쥐고 있었다.', 2),
    MockPassageTemplate.connection(
      '여자가 손잡이를 세 번 두드리자 붉은 색이 복도의 물 위로 길게 번졌다.',
      '우산을 든 여자와 붉은 문을 잇는 전이',
    ),
    MockPassageTemplate.dream('그때 문틈으로 물소리가 새어 나오기 시작했다.', 3),
  ],
);

const fallbackMockScene = MockSceneTemplate(
  title: '붉은 문',
  openImage: '닫힌 문 아래로 물이 흐르고 있었다.',
  elementLabels: ['물이 찬 복도', '붉은 문', '우산을 든 여자'],
  passages: [
    MockPassageTemplate.dream('복도에 물이 차 있었다.', 0),
    MockPassageTemplate.dream('끝에 붉은 문이 닫혀 있었다.', 1),
    MockPassageTemplate.dream('우산을 든 여자가 문 옆에 서 있었다.', 2),
  ],
);

MockSceneTemplate mockSceneTemplate({required bool isFallback}) {
  return isFallback ? fallbackMockScene : regularMockScene;
}
