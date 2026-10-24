import React from 'react';
import {render, screen} from '@testing-library/react';
import '@testing-library/jest-dom';
import App from './App';
test('renders the supplied storefront navigation', () => {
  render(<App />);
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});

