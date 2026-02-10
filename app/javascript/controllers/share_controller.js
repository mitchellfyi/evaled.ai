import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["buttonText"]

  async copyLink() {
    try {
      await navigator.clipboard.writeText(window.location.href)
      
      const originalText = this.buttonTextTarget.textContent
      this.buttonTextTarget.textContent = "Copied!"
      
      setTimeout(() => {
        this.buttonTextTarget.textContent = originalText
      }, 2000)
    } catch (err) {
      // Fallback for older browsers
      const textArea = document.createElement("textarea")
      textArea.value = window.location.href
      textArea.style.position = "fixed"
      textArea.style.left = "-999999px"
      document.body.appendChild(textArea)
      textArea.select()
      
      try {
        document.execCommand("copy")
        this.buttonTextTarget.textContent = "Copied!"
        setTimeout(() => {
          this.buttonTextTarget.textContent = "Copy Link"
        }, 2000)
      } catch (e) {
        console.error("Failed to copy:", e)
      }
      
      document.body.removeChild(textArea)
    }
  }
}
