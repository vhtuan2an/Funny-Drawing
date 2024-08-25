import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      textTheme: const TextTheme().copyWith(
        titleLarge: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          height: 0,
        ),
        titleMedium: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          height: 0,
        ),
        bodyMedium: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w300,
          height: 0,
        ),
        bodySmall: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w200,
          height: 0,
        ),
      ),
    );
  }
}

// theme builder (đừng dùng)
class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4279266135),
      surfaceTint: Color(4279266135),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4288869081),
      onPrimaryContainer: Color(4278198296),
      secondary: Color(4283130715),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4291684830),
      onSecondaryContainer: Color(4278657049),
      tertiary: Color(4282475126),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4291094527),
      onTertiaryContainer: Color(4278197805),
      error: Color(4290386458),
      onError: Color(4294967295),
      errorContainer: Color(4294957782),
      onErrorContainer: Color(4282449922),
      surface: Color(4294310902),
      onSurface: Color(4279704859),
      onSurfaceVariant: Color(4282337605),
      outline: Color(4285495669),
      outlineVariant: Color(4290759108),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020975),
      inversePrimary: Color(4287092413),
      primaryFixed: Color(4288869081),
      onPrimaryFixed: Color(4278198296),
      primaryFixedDim: Color(4287092413),
      onPrimaryFixedVariant: Color(4278210881),
      secondaryFixed: Color(4291684830),
      onSecondaryFixed: Color(4278657049),
      secondaryFixedDim: Color(4289907906),
      onSecondaryFixedVariant: Color(4281617476),
      tertiaryFixed: Color(4291094527),
      onTertiaryFixed: Color(4278197805),
      tertiaryFixedDim: Color(4289317858),
      onTertiaryFixedVariant: Color(4280830814),
      surfaceDim: Color(4292205527),
      surfaceBright: Color(4294310902),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4293916145),
      surfaceContainer: Color(4293521387),
      surfaceContainerHigh: Color(4293126885),
      surfaceContainerHighest: Color(4292797664),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278209597),
      surfaceTint: Color(4279266135),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4281434733),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4281354304),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4284578417),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4280567642),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4283922830),
      onTertiaryContainer: Color(4294967295),
      error: Color(4287365129),
      onError: Color(4294967295),
      errorContainer: Color(4292490286),
      onErrorContainer: Color(4294967295),
      surface: Color(4294310902),
      onSurface: Color(4279704859),
      onSurfaceVariant: Color(4282074433),
      outline: Color(4283916637),
      outlineVariant: Color(4285758840),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020975),
      inversePrimary: Color(4287092413),
      primaryFixed: Color(4281434733),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4278937684),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4284578417),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4282999128),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4283922830),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4282278004),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292205527),
      surfaceBright: Color(4294310902),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4293916145),
      surfaceContainer: Color(4293521387),
      surfaceContainerHigh: Color(4293126885),
      surfaceContainerHighest: Color(4292797664),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(4278200351),
      surfaceTint: Color(4279266135),
      onPrimary: Color(4294967295),
      primaryContainer: Color(4278209597),
      onPrimaryContainer: Color(4294967295),
      secondary: Color(4279117344),
      onSecondary: Color(4294967295),
      secondaryContainer: Color(4281354304),
      onSecondaryContainer: Color(4294967295),
      tertiary: Color(4278199606),
      onTertiary: Color(4294967295),
      tertiaryContainer: Color(4280567642),
      onTertiaryContainer: Color(4294967295),
      error: Color(4283301890),
      onError: Color(4294967295),
      errorContainer: Color(4287365129),
      onErrorContainer: Color(4294967295),
      surface: Color(4294310902),
      onSurface: Color(4278190080),
      onSurfaceVariant: Color(4280100386),
      outline: Color(4282074433),
      outlineVariant: Color(4282074433),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4281020975),
      inversePrimary: Color(4289527010),
      primaryFixed: Color(4278209597),
      onPrimaryFixed: Color(4294967295),
      primaryFixedDim: Color(4278203432),
      onPrimaryFixedVariant: Color(4294967295),
      secondaryFixed: Color(4281354304),
      onSecondaryFixed: Color(4294967295),
      secondaryFixedDim: Color(4279906602),
      onSecondaryFixedVariant: Color(4294967295),
      tertiaryFixed: Color(4280567642),
      onTertiaryFixed: Color(4294967295),
      tertiaryFixedDim: Color(4278726722),
      onTertiaryFixedVariant: Color(4294967295),
      surfaceDim: Color(4292205527),
      surfaceBright: Color(4294310902),
      surfaceContainerLowest: Color(4294967295),
      surfaceContainerLow: Color(4293916145),
      surfaceContainer: Color(4293521387),
      surfaceContainerHigh: Color(4293126885),
      surfaceContainerHighest: Color(4292797664),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4287092413),
      surfaceTint: Color(4287092413),
      onPrimary: Color(4278204460),
      primaryContainer: Color(4278210881),
      onPrimaryContainer: Color(4288869081),
      secondary: Color(4289907906),
      onSecondary: Color(4280104238),
      secondaryContainer: Color(4281617476),
      onSecondaryContainer: Color(4291684830),
      tertiary: Color(4289317858),
      onTertiary: Color(4279120966),
      tertiaryContainer: Color(4280830814),
      onTertiaryContainer: Color(4291094527),
      error: Color(4294948011),
      onError: Color(4285071365),
      errorContainer: Color(4287823882),
      onErrorContainer: Color(4294957782),
      surface: Color(4279178514),
      onSurface: Color(4292797664),
      onSurfaceVariant: Color(4290759108),
      outline: Color(4287206286),
      outlineVariant: Color(4282337605),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292797664),
      inversePrimary: Color(4279266135),
      primaryFixed: Color(4288869081),
      onPrimaryFixed: Color(4278198296),
      primaryFixedDim: Color(4287092413),
      onPrimaryFixedVariant: Color(4278210881),
      secondaryFixed: Color(4291684830),
      onSecondaryFixed: Color(4278657049),
      secondaryFixedDim: Color(4289907906),
      onSecondaryFixedVariant: Color(4281617476),
      tertiaryFixed: Color(4291094527),
      onTertiaryFixed: Color(4278197805),
      tertiaryFixedDim: Color(4289317858),
      onTertiaryFixedVariant: Color(4280830814),
      surfaceDim: Color(4279178514),
      surfaceBright: Color(4281613112),
      surfaceContainerLowest: Color(4278783757),
      surfaceContainerLow: Color(4279704859),
      surfaceContainer: Color(4279968030),
      surfaceContainerHigh: Color(4280625961),
      surfaceContainerHighest: Color(4281349683),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4287355585),
      surfaceTint: Color(4287092413),
      onPrimary: Color(4278197012),
      primaryContainer: Color(4283473800),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4290171334),
      onSecondary: Color(4278393364),
      secondaryContainer: Color(4286420621),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4289581031),
      onTertiary: Color(4278196517),
      tertiaryContainer: Color(4285765035),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294949553),
      onError: Color(4281794561),
      errorContainer: Color(4294923337),
      onErrorContainer: Color(4278190080),
      surface: Color(4279178514),
      onSurface: Color(4294376696),
      onSurfaceVariant: Color(4291022280),
      outline: Color(4288390560),
      outlineVariant: Color(4286285185),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292797664),
      inversePrimary: Color(4278211138),
      primaryFixed: Color(4288869081),
      onPrimaryFixed: Color(4278195471),
      primaryFixedDim: Color(4287092413),
      onPrimaryFixedVariant: Color(4278206001),
      secondaryFixed: Color(4291684830),
      onSecondaryFixed: Color(4278195471),
      secondaryFixedDim: Color(4289907906),
      onSecondaryFixedVariant: Color(4280498995),
      tertiaryFixed: Color(4291094527),
      onTertiaryFixed: Color(4278194974),
      tertiaryFixedDim: Color(4289317858),
      onTertiaryFixedVariant: Color(4279581260),
      surfaceDim: Color(4279178514),
      surfaceBright: Color(4281613112),
      surfaceContainerLowest: Color(4278783757),
      surfaceContainerLow: Color(4279704859),
      surfaceContainer: Color(4279968030),
      surfaceContainerHigh: Color(4280625961),
      surfaceContainerHighest: Color(4281349683),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(4293722102),
      surfaceTint: Color(4287092413),
      onPrimary: Color(4278190080),
      primaryContainer: Color(4287355585),
      onPrimaryContainer: Color(4278190080),
      secondary: Color(4293722102),
      onSecondary: Color(4278190080),
      secondaryContainer: Color(4290171334),
      onSecondaryContainer: Color(4278190080),
      tertiary: Color(4294507519),
      onTertiary: Color(4278190080),
      tertiaryContainer: Color(4289581031),
      onTertiaryContainer: Color(4278190080),
      error: Color(4294965753),
      onError: Color(4278190080),
      errorContainer: Color(4294949553),
      onErrorContainer: Color(4278190080),
      surface: Color(4279178514),
      onSurface: Color(4294967295),
      onSurfaceVariant: Color(4294180343),
      outline: Color(4291022280),
      outlineVariant: Color(4291022280),
      shadow: Color(4278190080),
      scrim: Color(4278190080),
      inverseSurface: Color(4292797664),
      inversePrimary: Color(4278202662),
      primaryFixed: Color(4289198045),
      onPrimaryFixed: Color(4278190080),
      primaryFixedDim: Color(4287355585),
      onPrimaryFixedVariant: Color(4278197012),
      secondaryFixed: Color(4292013538),
      onSecondaryFixed: Color(4278190080),
      secondaryFixedDim: Color(4290171334),
      onSecondaryFixedVariant: Color(4278393364),
      tertiaryFixed: Color(4291750911),
      onTertiaryFixed: Color(4278190080),
      tertiaryFixedDim: Color(4289581031),
      onTertiaryFixedVariant: Color(4278196517),
      surfaceDim: Color(4279178514),
      surfaceBright: Color(4281613112),
      surfaceContainerLowest: Color(4278783757),
      surfaceContainerLow: Color(4279704859),
      surfaceContainer: Color(4279968030),
      surfaceContainerHigh: Color(4280625961),
      surfaceContainerHighest: Color(4281349683),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
