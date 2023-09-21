class LetterId {
    [string]$Value
    [char]$Letter
    [System.ConsoleColor]$Color

    LetterId([string]$value, [char]$letter, [System.ConsoleColor]$color) {
        $this.Value = $value
        $this.Letter = $letter
        $this.Color = $color
    }
}

class LetterIdProvider {
    $LetterIndexOffset = 65 # ASCII code for A

    $CurrentLetterIndex = 0
    $CurrentColorIndex = 0
    $Colors = @(
        [System.ConsoleColor]::DarkRed,
        [System.ConsoleColor]::DarkGreen,
        [System.ConsoleColor]::DarkYellow,
        [System.ConsoleColor]::DarkBlue,
        [System.ConsoleColor]::DarkMagenta,
        [System.ConsoleColor]::DarkCyan,
        [System.ConsoleColor]::Red,
        [System.ConsoleColor]::Green,
        [System.ConsoleColor]::Yellow,
        [System.ConsoleColor]::Blue,
        [System.ConsoleColor]::Magenta,
        [System.ConsoleColor]::Cyan
    )

    [LetterId]Next([string]$value) {
        $letterIndex = $this.CurrentLetterIndex + $this.LetterIndexOffset
        $colorIndex = $this.Colors[$this.CurrentColorIndex]

        $this.CurrentLetterIndex++
        $this.CurrentColorIndex++

        if ($this.CurrentColorIndex -ge $this.Colors.Length) {
            $this.CurrentColorIndex = 0
        }

        $id = [LetterId]::new($value, [char]$letterIndex, $colorIndex)
        return $id
    }
}
