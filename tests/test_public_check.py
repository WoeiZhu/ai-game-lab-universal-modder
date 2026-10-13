"""Synthetic checks only; no real secrets or external services."""
import unittest

from check_public_files import inspect


class PublicCheckTests(unittest.TestCase):
    def labels(self, data, path='README.md'):
        return {finding[2] for finding in inspect(path, data)}

    def test_token_detection(self):
        token = ('gh' + 'p_' + 'x' * 36).encode()
        self.assertIn('credential-prefix', self.labels(token))

    def test_generic_secret(self):
        assignment = ('API_' + 'KEY=' + 'x' * 24).encode()
        self.assertIn('credential-assignment', self.labels(assignment))

    def test_private_path(self):
        path = ('Q:' + chr(92) + 'Users' + chr(92) + 'sample').encode()
        self.assertIn('absolute-windows-path', self.labels(path))

    def test_drive_url(self):
        url = ('https://' + 'drive' + '.google.com/file/d/example').encode()
        self.assertIn('private-drive-url', self.labels(url))

    def test_private_filename_and_binary(self):
        self.assertIn('not-in-public-allowlist', self.labels(b'private', 'handoff/private.md'))
        self.assertIn('non-utf8', self.labels(bytes([255])))
        self.assertIn('binary-content', self.labels(bytes([0])))

    def test_placeholder_and_local_service(self):
        self.assertEqual(set(), self.labels(b'COMFYUI_URL=http://127.0.0.1:8000\nBLENDER=\n'))

    def test_line_number_without_value(self):
        token = ('gh' + 'p_' + 'x' * 36).encode()
        findings = inspect('README.md', b'header\n' + token)
        self.assertEqual(('README.md', 2, 'credential-prefix'), findings[0])
        self.assertNotIn(token.decode(), repr(findings))


if __name__ == '__main__':
    unittest.main()
