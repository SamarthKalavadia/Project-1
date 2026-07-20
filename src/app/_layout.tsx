import { DarkTheme, DefaultTheme, ThemeProvider } from '@react-navigation/native';
import * as SplashScreen from 'expo-splash-screen';
import { useColorScheme } from 'react-native';

import { AnimatedSplashOverlay } from '@/components/animated-icon';
import AppTabs from '@/components/app-tabs';
import { RidesProvider, useRides } from '@/context/RidesContext';
import { LoginScreen } from '@/components/LoginScreen';

SplashScreen.preventAutoHideAsync();

export default function TabLayout() {
  const colorScheme = useColorScheme();
  return (
    <ThemeProvider value={colorScheme === 'dark' ? DarkTheme : DefaultTheme}>
      <RidesProvider>
        <AnimatedSplashOverlay />
        <AppLayoutContent />
      </RidesProvider>
    </ThemeProvider>
  );
}

function AppLayoutContent() {
  const { currentUser } = useRides();

  if (!currentUser) {
    return <LoginScreen />;
  }

  return <AppTabs />;
}
