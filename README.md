# Security Check
This is a free bash script that helps rate your security for developers.
If you run a vagrant box this should be run in both the vagrant box and on the host computer to verify password strength of the host computer.


## Password checklist
This script checks against the sudoers file for verification of the inputted password.
It checks several password constraints:
- Length is at least 8 characters
- Password contains numbers
- Password contains letters
- Password contains punctuation

## SSH Key checklist
The script searches a directory for all SSH keys and greps for the term `ENCRYPTED`
Features:
- Verifies multiple ssh keys
- Verifies if the key is encrypted with a password
