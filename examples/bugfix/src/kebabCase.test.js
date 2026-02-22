import { describe, it, expect } from 'vitest';
import { kebabCase } from './kebabCase.js';

describe('kebabCase', () => {
  it('converts camelCase to kebab-case', () => {
    expect(kebabCase('helloWorld')).toBe('hello-world');
  });

  it('converts PascalCase to kebab-case', () => {
    expect(kebabCase('HelloWorld')).toBe('hello-world');
  });

  it('converts spaces to hyphens', () => {
    expect(kebabCase('hello world')).toBe('hello-world');
  });

  it('handles already kebab-cased input', () => {
    expect(kebabCase('hello-world')).toBe('hello-world');
  });

  it('returns empty string for nullish input', () => {
    expect(kebabCase(null)).toBe('');
    expect(kebabCase(undefined)).toBe('');
    expect(kebabCase('')).toBe('');
  });

  it('handles letter-to-number transitions', () => {
    expect(kebabCase('version2Release')).toBe('version-2-release');
  });

  it('handles number-to-letter transitions', () => {
    expect(kebabCase('abc123def')).toBe('abc-123-def');
  });

  it('handles mixed numbers in camelCase', () => {
    expect(kebabCase('layer2Output')).toBe('layer-2-output');
  });
});
