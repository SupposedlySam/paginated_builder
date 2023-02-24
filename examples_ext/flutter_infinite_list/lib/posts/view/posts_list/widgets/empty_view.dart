import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final subtitleTheme = Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: Colors.black54,
          fontSize: 14,
          letterSpacing: -0.0,
        );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.emoji_people,
          size: 62,
          color: Theme.of(context).primaryColor,
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "You're all caught up!",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontSize: 26,
                      letterSpacing: 1.1,
                      height: 1.5,
                    ),
              ),
              SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  text: "take a",
                  style: subtitleTheme,
                  children: [
                    TextSpan(
                      text: " deep breath".toUpperCase(),
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontFamily: 'Helvetica',
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 1.2,
                            wordSpacing: -2,
                            fontSize: 18,
                          ),
                      children: [
                        TextSpan(
                          text: " and relax",
                          style: subtitleTheme,
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
