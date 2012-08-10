/**************************************************************************************************
* Copyright (c) 2012 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
* associated documentation files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge, publish, distribute,
* sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or
* substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
* NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
* DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
* OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*
***************************************************************************************************/

#ifndef PARSER_H
#define PARSER_H

#include <QtCore/QString>
#include <QtCore/QVector>
#include <QtCore/QLinkedList>

#include "text_segment.h"

class Parser
{
public:
    Parser(TerminalScreen *screen);

    void addData(const QByteArray &data);

private:

    enum DecodeState {
        PlainText,
        DecodeC0,
        DecodeC1_7bit,
        DecodeCSI,
        DecodeOSC
    };

    enum DecodeOSCState {
        ChangeWindowAndIconName,
        ChangeIconTitle,
        ChangeWindowTitle,
        None
    };

    void decodeC0(uchar character);
    void decodeC1_7bit(uchar character);
    void decodeParameters(uchar character);
    void decodeCSI(uchar character);
    void decodeOSC(uchar character);
    void tokenFinished();

    DecodeState m_decode_state;
    DecodeOSCState m_decode_osc_state;

    QByteArray m_current_data;

    int m_current_token_start;
    int m_currrent_position;

    QChar m_intermediate_char;

    QByteArray m_parameter_string;
    QVector<ushort> m_parameters;

    TerminalScreen *m_screen;
};

#endif // PARSER_H