class OutputSegment {
    [string]$Text
    [System.ConsoleColor]$ForegroundColor

    OutputSegment([string]$text) {
        $this.Text = $text
        $this.ForegroundColor = [System.Console]::ForegroundColor
    }

    OutputSegment([string]$text, [System.ConsoleColor]$foregroundColor) {
        $this.Text = $text
        $this.ForegroundColor = $foregroundColor
    }
}
