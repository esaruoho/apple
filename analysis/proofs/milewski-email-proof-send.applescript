tell application "Mail"
 set m to make new outgoing message with properties {subject:"PDF pipeline proof a9d87eab12 — John-Milewski-Superlight", content:"Please analyze the attached original six-page PDF. Identify its title and author, explain the proposed mechanism and supporting observations, distinguish source statements from inference, and include evidence from the beginning and end of the document so we can verify attachment extraction. This is an end-to-end PDF attachment pipeline test. Proof ID: a9d87eab12.", sender:"esaruoho@gmail.com", visible:false}
 tell m
  make new to recipient at end of to recipients with properties {address:"cloudcity-llm@agentmail.to"}
  make new attachment with properties {file name:POSIX file "/Users/esaruoho/John-Milewski-Superlight.pdf"} at after the last paragraph
 end tell
 send m
end tell
