import js from '@eslint/js';
import globals from 'globals';
import react from 'eslint-plugin-react';
export default [js.configs.recommended, {files: ['src/**/*.{js,jsx}'], plugins: {react}, languageOptions: {ecmaVersion: 2022, sourceType: 'module', parserOptions: {ecmaFeatures: {jsx: true}}, globals: {...globals.browser, ...globals.node, ...globals.vitest}}, rules: {'no-unused-vars': 'off', 'react/jsx-uses-vars': 'error'}}];

