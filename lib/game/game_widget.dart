import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photopuzzle/game/game_config.dart';
import 'package:photopuzzle/game/game_engine.dart';
import 'package:photopuzzle/game/game_painter.dart';
import 'package:photopuzzle/game/image_node.dart';
import 'package:photopuzzle/game/puzzle_util.dart';
import 'package:vibrate/vibrate.dart';

class GameWidget extends StatefulWidget {
  final Size size;
  final Uint8List bytes;
  final int level;
  GameWidget(this.size, this.bytes, this.level);

  @override
  State<StatefulWidget> createState() {
    return GameWidgetState(size, bytes, level);
  }
}

class GameWidgetState extends State<GameWidget> with TickerProviderStateMixin {
  final Size size;
  PuzzleUtil puzzleUtil;
  List<ImageNode> nodes;

  Animation<int> alpha;
  AnimationController controller;
  Map<int, ImageNode> nodeMap = {};

  int level;
  Uint8List bytes;
  ImageNode hitNode;

  double downX, downY, newX, newY;
  int emptyIndex;
  Direction direction;
  bool needDraw = true;
  List<ImageNode> hitNodeList = [];

  GameState gameState = GameState.loading;

  GameWidgetState(this.size, this.bytes, this.level) {
    puzzleUtil = PuzzleUtil();
    emptyIndex = level * level - 1;

    puzzleUtil.init(bytes, size, level).then((val) {
      setState(() {
        nodes = puzzleUtil.doTask();
        GameEngine.makeRandom(nodes);
        setState(() {
          gameState = GameState.play;
        });
        showStartAnimation();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (gameState == GameState.loading) {
      return Center(
        child: Text('Loading'),
      );
    } else if (gameState == GameState.complete) {
      return Center(
          child: ElevatedButton(
        onPressed: () {
          GameEngine.makeRandom(nodes);
          setState(() {
            gameState = GameState.play;
          });
          showStartAnimation();
        },
        child: Text('Restart'),
      ));
    } else {
      return Stack(
        children: [
          GestureDetector(
            onPanDown: onPanDown,
            onPanUpdate: onPanUpdate,
            onPanEnd: onPanUp,
            child: Container(
              child: CustomPaint(
                  painter: GamePainter(nodes, level, hitNode, hitNodeList,
                      direction, downX, downY, newX, newY, needDraw),
                  size: Size.infinite),
            ),
          ),
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void showStartAnimation() {
    needDraw = true;
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    alpha = IntTween(begin: 0, end: 100).animate(controller);
    nodes.forEach((node) {
      nodeMap[node.curIndex] = node;

      var rect = node.rect;
      var dstRect = puzzleUtil.getOkRectF(
          node.curIndex % level, (node.curIndex / level).floor());

      final dealtX = dstRect.left - rect.left;
      final dealtY = dstRect.top - rect.top;

      final oldX = rect.left;
      final oldY = rect.top;

      alpha.addListener(() {
        var oldNewX2 = alpha.value * dealtX / 100;
        var oldNewY2 = alpha.value * dealtY / 100;
        setState(() {
          node.rect = Rect.fromLTWH(
              oldX + oldNewX2, oldY + oldNewY2, rect.width, rect.height);
        });
      });
    });
    alpha.addStatusListener((AnimationStatus val) {
      if (val == AnimationStatus.completed) {
        needDraw = false;
      }
    });
    controller.forward();
  }

  void onPanDown(DragDownDetails details) {
    if (controller != null && controller.isAnimating) {
      return;
    }
    Vibrate.feedback(FeedbackType.heavy);
    needDraw = true;
    var referenceBox = context.findRenderObject() as RenderBox;
    var localPosition = referenceBox.globalToLocal(details.globalPosition);
    for (var node in nodes) {
      if (node.rect.contains(localPosition)) {
        hitNode = node;
        direction = isBetween(hitNode, emptyIndex);
        if (direction != Direction.none) {
          newX = downX = localPosition.dx;
          newY = downY = localPosition.dy;

          nodes.remove(hitNode);
          nodes.add(hitNode);
        }
        setState(() {});
        break;
      }
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (hitNode == null) {
      return;
    }
    var referenceBox = context.findRenderObject() as RenderBox;
    var localPosition = referenceBox.globalToLocal(details.globalPosition);
    newX = localPosition.dx;
    newY = localPosition.dy;
    if (direction == Direction.top) {
      newY = min(downY, max(newY, downY - hitNode.rect.width));
    } else if (direction == Direction.bottom) {
      newY = max(downY, min(newY, downY + hitNode.rect.width));
    } else if (direction == Direction.left) {
      newX = min(downX, max(newX, downX - hitNode.rect.width));
    } else if (direction == Direction.right) {
      newX = max(downX, min(newX, downX + hitNode.rect.width));
    }

    setState(() {});
  }

  void onPanUp(DragEndDetails details) {
    if (hitNode == null) {
      return;
    }
    needDraw = false;
    if (direction == Direction.top) {
      if (-(newY - downY) > hitNode.rect.width / 2) {
        swapEmpty();
      }
    } else if (direction == Direction.bottom) {
      if (newY - downY > hitNode.rect.width / 2) {
        swapEmpty();
      }
    } else if (direction == Direction.left) {
      if (-(newX - downX) > hitNode.rect.width / 2) {
        swapEmpty();
      }
    } else if (direction == Direction.right) {
      if (newX - downX > hitNode.rect.width / 2) {
        swapEmpty();
      }
    }

    hitNodeList.clear();
    hitNode = null;

    var isComplete = true;
    nodes.forEach((node) {
      if (node.curIndex != node.index) {
        isComplete = false;
      }
    });
    if (isComplete) {
      gameState = GameState.complete;
    }

    setState(() {});
  }

  Direction isBetween(ImageNode node, int emptyIndex) {
    var x = emptyIndex % level;
    var y = (emptyIndex / level).floor();

    var x2 = node.curIndex % level;
    var y2 = (node.curIndex / level).floor();

    if (x == x2) {
      if (y2 < y) {
        for (var index = y2; index < y; ++index) {
          hitNodeList.add(nodeMap[index * level + x]);
        }
        return Direction.bottom;
      } else if (y2 > y) {
        for (var index = y2; index > y; --index) {
          hitNodeList.add(nodeMap[index * level + x]);
        }
        return Direction.top;
      }
    }
    if (y == y2) {
      if (x2 < x) {
        for (var index = x2; index < x; ++index) {
          hitNodeList.add(nodeMap[y * level + index]);
        }
        return Direction.right;
      } else if (x2 > x) {
        for (var index = x2; index > x; --index) {
          hitNodeList.add(nodeMap[y * level + index]);
        }
        return Direction.left;
      }
    }
    return Direction.none;
  }

  void swapEmpty() {
    var v = -level;
    if (direction == Direction.right) {
      v = 1;
    } else if (direction == Direction.left) {
      v = -1;
    } else if (direction == Direction.bottom) {
      v = level;
    }
    hitNodeList.forEach((node) {
      node.curIndex += v;
      nodeMap[node.curIndex] = node;
      node.rect = puzzleUtil.getOkRectF(
          node.curIndex % level, (node.curIndex / level).floor());
    });
    emptyIndex -= v * hitNodeList.length;
  }
}
