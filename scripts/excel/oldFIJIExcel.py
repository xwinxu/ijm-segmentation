"""Convert tsv into excel."""
import sys
import argparse
from argparse import ArgumentParser
import xlwt

style = xlwt.XFStyle()
font = xlwt.Font()
font.bold = True
style.font = font
borders = xlwt.Borders()
borders.bottom = xlwt.Borders.DASHED
style.borders = borders


def read_tsv(tsvfile):
    """Reads tsv file."""
    data = []
    with open(str(tsvfile), 'r') as tsv:
        for line in tsv:
            data.append([word.strip() for word in line.split("	")])
    return data


def write_xl1(master_list, outputname, outputdir):
    """Writes an excel file with content from master_list into separate sheets."""
    # print(master_list)
    wb = xlwt.Workbook()
    for j in range(len(master_list)):
        if 'Dummy' in master_list[j][0]:
            sheet = wb.add_sheet(str(master_list[j][0]))
            start_index = j
            # print(start_index)
            for i in range((start_index+1), len(master_list)):
                if len(master_list[i]) != 3:
                    end_index = i
                    temp_list = master_list[start_index:end_index]
                    # print(temp_list)
                    for row_index in range(len(temp_list)):
                        for col_index in range(len(temp_list[row_index])):
                            sheet.write(row_index, col_index, temp_list[row_index][col_index])
                    filename = str(outputdir) + '/' + str(outputname) + '.xls'
                    wb.save(filename)
                    break


def write_xl2(master_list, outputname, outputdir):
    """Writes an excel file with content from master_list into 1 sheet only."""
    # print(master_list)
    wb = xlwt.Workbook()
    sheet = wb.add_sheet(str(outputname))
    last_column = 0
    longest_column = 0
    filename = ''
    j = 0
    for j in range(len(master_list)):
        if 'Du' in master_list[j][0][0:2]:
            start_index = j + 1
            for i in range(start_index, len(master_list)):
                # if len(master_list[i]) != 3:
                if (i == len(master_list)-1) or ('Dummy' in master_list[i][0]):
                    # separator for the experiments
                    end_index = i
                    if i != len(master_list)-1:
                        temp_list = master_list[start_index:end_index]
                    else:
                        temp_list = master_list[start_index:end_index+1]
                    print(temp_list)
                    for row_index in range(len(temp_list)):
                        if len(temp_list) > longest_column:
                            longest_column = len(temp_list)
                        for col_index in range(len(temp_list[row_index])):
                            new_col = (last_column + col_index)
                            if len(temp_list[row_index]) != 1:
                                sheet.write(row_index, new_col, temp_list[row_index][col_index])
                            else:
                                sheet.write(row_index, new_col, temp_list[row_index][col_index])
                                sheet.write(row_index, new_col+1, '% Coverage', style=style)
                                sheet.write(row_index, new_col+2, '% Blob', style=style)
                    print(len(temp_list[1]))
                    last_column += len(temp_list[1])
                    filename = str(outputdir) + '/' + str(outputname) + '.xls'
                    wb.save(filename)
                    break
    sheet.write(longest_column + 1, 0, 'Summary Stats')
    sheet.write(longest_column + 2, 0, 'Mean')
    sheet.write(longest_column + 3, 0, 'Median')
    sheet.write(longest_column + 4, 0, 'Min')
    sheet.write(longest_column + 5, 0, 'Max')
    sheet.write(longest_column + 6, 0, 'Standard Dev')
    wb.save(filename)


if __name__ == '__main__':
    def str2bool(v):
        """Make switches with default values but with correct parser error."""
        if v.lower() in ('yes', 'true', 't', 'y', '1'):
            return True
        elif v.lower() in ('no', 'false', 'f', 'n', '0'):
            return False
        else:
            raise argparse.ArgumentTypeError('Boolean value expected.')
    # parser.add_argument('--is_debug', default=False, type=lambda x: (str(x).lower() == 'true'))
    # parser = argparse.ArgumentParser(description='A tsv to excel converter for Bellas muscle fibres')
    # parser.add_argument('tsvfile', help='tsv file generated from fiji')
    # parser.add_argument('outputname', help='excel file name')
    # parser.add_argument('outputdir', help='excel output directory')
    # parser.add_argument('numbersheets', nargs='?', type=str2bool, const=True, default='False',
    #                     help='specify if you want separate sheets per experiment or not')
    # args = parser.parse_args()
    # master = read_tsv(args.tsvfile)
    # if args.numbersheets:
    #     print('1')
    #     write_xl1(master, args.outputname, args.outputdir)
    # else:
    #     print('2')
    #     write_xl2(master, args.outputname, args.outputdir)
    master = read_tsv(sys.argv[1])
    if sys.argv[4] is "True":
        print('1')
        write_xl1(master, sys.argv[2], sys.argv[3])
    else:
        print('2')
        write_xl2(master, sys.argv[2], sys.argv[3])
