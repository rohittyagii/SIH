import re

with open("lib/main.dart", "r") as f:
    content = f.read()

# 1. Add import 'dart:ui' as ui;
if "import 'dart:ui' as ui;" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'dart:ui' as ui;\nimport 'package:flutter/material.dart';")

# 2. Replace the Scaffold block in _MainApp
search_block = """    } else {
      mainContent = Scaffold(
        key: const ValueKey('tabs'),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(tab),
                      child: _tabBody(context, ref, tab, history, todayDone, isDark, streak),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNav(
                active: tab,
                onTab: (t) => ref.read(tabProvider.notifier).state = t,
              ),
            ),
          ],
        ),
      );
    }"""

replace_block = """    } else {
      mainContent = Scaffold(
        key: const ValueKey('tabs'),
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: context.rrBg,
        body: Stack(
          children: [
            // 1. The Tabs Content (now directly in Stack to go edge-to-edge)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(tab),
                child: _tabBody(context, ref, tab, history, todayDone, isDark, streak),
              ),
            ),
            
            // 2. Top Blurry Gradient Mask (for status bar legibility)
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).padding.top + 32,
              child: IgnorePointer(
                child: ClipRect(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.3, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(color: context.rrBg.withOpacity(0.6)),
                    ),
                  ),
                ),
              ),
            ),

            // 3. Bottom Blurry Gradient Mask (so content smoothly vanishes under nav island)
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 120, 
              child: IgnorePointer(
                child: ClipRect(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.1, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.dstIn,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: Container(color: context.rrBg.withOpacity(0.6)),
                    ),
                  ),
                ),
              ),
            ),

            // 4. Floating Navigation Island
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNav(
                active: tab,
                onTab: (t) => ref.read(tabProvider.notifier).state = t,
              ),
            ),
          ],
        ),
      );
    }"""

content = content.replace(search_block, replace_block)

with open("lib/main.dart", "w") as f:
    f.write(content)

print("Updated main.dart with edge-to-edge gradients")
