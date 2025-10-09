  // Добавляем поддержку AMOLED темы
  ExtendedThemeMode _currentExtendedTheme = ExtendedThemeMode.system;
  bool get isAmoledMode => _currentExtendedTheme == ExtendedThemeMode.amoled;

  ExtendedThemeMode get currentExtendedTheme => _currentExtendedTheme;

  void switchExtendedTheme(ExtendedThemeMode newTheme) {
    setState(() {
      _currentExtendedTheme = newTheme;
    });

    switch (newTheme) {
      case ExtendedThemeMode.light:
        ThemeController.of(context).setThemeMode(ThemeMode.light);
        _saveAmoledSetting(false);
        break;
      case ExtendedThemeMode.dark:
        ThemeController.of(context).setThemeMode(ThemeMode.dark);
        _saveAmoledSetting(false);
        break;
      case ExtendedThemeMode.amoled:
        ThemeController.of(context).setThemeMode(ThemeMode.dark);
        _saveAmoledSetting(true);
        break;
      case ExtendedThemeMode.system:
        ThemeController.of(context).setThemeMode(ThemeMode.system);
        _saveAmoledSetting(false);
        break;
    }
  }

  void _saveAmoledSetting(bool useAmoled) {
    Matrix.of(context).store.setBool('useAmoledTheme', useAmoled);
  }

  bool get useAmoledTheme => 
      Matrix.of(context).store.getBool('useAmoledTheme') ?? false;
