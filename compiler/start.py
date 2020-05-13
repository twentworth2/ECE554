import ft_parser
import ft_generator
f = open('high_level3.ft')
ft_parser.test(f)
ft_generator.generate('ast.txt')